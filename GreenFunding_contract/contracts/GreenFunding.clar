;; GreenFunding Smart Contract
;; An environmental grant allocation platform for eco-project financing and impact measurement

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-project-not-active (err u105))
(define-constant err-unauthorized (err u106))
(define-constant err-invalid-status (err u107))

;; Data Variables
(define-data-var project-counter uint u0)
(define-data-var grant-counter uint u0)
(define-data-var total-funding uint u0)

;; Project Status Enum
(define-constant status-pending u0)
(define-constant status-approved u1)
(define-constant status-funded u2)
(define-constant status-completed u3)
(define-constant status-rejected u4)

;; Data Maps
(define-map projects
    uint
    {
        owner: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        funding-goal: uint,
        current-funding: uint,
        status: uint,
        category: (string-ascii 50),
        impact-metrics: (string-ascii 200),
        created-at: uint,
        approved-at: (optional uint),
        completed-at: (optional uint)
    }
)

(define-map grants
    uint
    {
        project-id: uint,
        funder: principal,
        amount: uint,
        granted-at: uint,
        message: (optional (string-ascii 200))
    }
)

(define-map project-funders
    {project-id: uint, funder: principal}
    uint
)

(define-map user-contributions
    principal
    uint
)

(define-map project-evaluators
    uint
    (list 10 principal)
)

;; Read-only functions

(define-read-only (get-project (project-id uint))
    (map-get? projects project-id)
)

(define-read-only (get-grant (grant-id uint))
    (map-get? grants grant-id)
)

(define-read-only (get-project-funding (project-id uint) (funder principal))
    (map-get? project-funders {project-id: project-id, funder: funder})
)

(define-read-only (get-user-total-contributions (user principal))
    (default-to u0 (map-get? user-contributions user))
)

(define-read-only (get-total-funding)
    (var-get total-funding)
)

(define-read-only (get-project-count)
    (var-get project-counter)
)

(define-read-only (get-grant-count)
    (var-get grant-counter)
)

(define-read-only (get-contract-owner)
    contract-owner
)

;; Public functions

;; Submit a new eco-project for funding
(define-public (submit-project
    (title (string-ascii 100))
    (description (string-ascii 500))
    (funding-goal uint)
    (category (string-ascii 50))
    (impact-metrics (string-ascii 200)))
    (let
        (
            (project-id (+ (var-get project-counter) u1))
        )
        (asserts! (> funding-goal u0) err-invalid-amount)
        (map-set projects project-id
            {
                owner: tx-sender,
                title: title,
                description: description,
                funding-goal: funding-goal,
                current-funding: u0,
                status: status-pending,
                category: category,
                impact-metrics: impact-metrics,
                created-at: block-height,
                approved-at: none,
                completed-at: none
            }
        )
        (var-set project-counter project-id)
        (ok project-id)
    )
)

;; Approve a project (only contract owner)
(define-public (approve-project (project-id uint))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (get status project) status-pending) err-invalid-status)
        (map-set projects project-id
            (merge project {
                status: status-approved,
                approved-at: (some block-height)
            })
        )
        (ok true)
    )
)

;; Reject a project (only contract owner)
(define-public (reject-project (project-id uint))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (get status project) status-pending) err-invalid-status)
        (map-set projects project-id
            (merge project {status: status-rejected})
        )
        (ok true)
    )
)

;; Fund an approved project
(define-public (fund-project (project-id uint) (amount uint) (message (optional (string-ascii 200))))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
            (grant-id (+ (var-get grant-counter) u1))
            (current-user-funding (default-to u0 (get-project-funding project-id tx-sender)))
            (current-user-contributions (get-user-total-contributions tx-sender))
        )
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (is-eq (get status project) status-approved) err-project-not-active)
        (asserts! (<= (+ (get current-funding project) amount) (get funding-goal project)) err-invalid-amount)

        ;; Transfer STX from funder to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

        ;; Record the grant
        (map-set grants grant-id
            {
                project-id: project-id,
                funder: tx-sender,
                amount: amount,
                granted-at: block-height,
                message: message
            }
        )

        ;; Update project funding
        (map-set projects project-id
            (merge project {
                current-funding: (+ (get current-funding project) amount),
                status: (if (is-eq (+ (get current-funding project) amount) (get funding-goal project))
                           status-funded
                           status-approved)
            })
        )

        ;; Update user contribution tracking
        (map-set project-funders
            {project-id: project-id, funder: tx-sender}
            (+ current-user-funding amount)
        )

        (map-set user-contributions tx-sender (+ current-user-contributions amount))

        ;; Update counters
        (var-set grant-counter grant-id)
        (var-set total-funding (+ (var-get total-funding) amount))

        (ok grant-id)
    )
)

;; Mark project as completed (only project owner)
(define-public (complete-project (project-id uint) (final-impact-report (string-ascii 200)))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get owner project)) err-unauthorized)
        (asserts! (is-eq (get status project) status-funded) err-invalid-status)
        (map-set projects project-id
            (merge project {
                status: status-completed,
                completed-at: (some block-height),
                impact-metrics: final-impact-report
            })
        )
        (ok true)
    )
)

;; Withdraw funds for a funded project (only project owner)
(define-public (withdraw-project-funds (project-id uint))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
            (withdrawal-amount (get current-funding project))
        )
        (asserts! (is-eq tx-sender (get owner project)) err-unauthorized)
        (asserts! (or (is-eq (get status project) status-funded)
                     (is-eq (get status project) status-completed)) err-invalid-status)
        (asserts! (> withdrawal-amount u0) err-insufficient-funds)

        ;; Transfer funds from contract to project owner
        (try! (as-contract (stx-transfer? withdrawal-amount tx-sender (get owner project))))

        ;; Update project to show funds withdrawn
        (map-set projects project-id
            (merge project {current-funding: u0})
        )

        (ok withdrawal-amount)
    )
)

;; Add evaluator to project (only contract owner)
(define-public (add-project-evaluator (project-id uint) (evaluator principal))
    (let
        (
            (current-evaluators (default-to (list) (map-get? project-evaluators project-id)))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (get-project project-id)) err-not-found)
        (map-set project-evaluators project-id
            (unwrap! (as-max-len? (append current-evaluators evaluator) u10) err-invalid-amount)
        )
        (ok true)
    )
)

;; Get project evaluators
(define-read-only (get-project-evaluators (project-id uint))
    (map-get? project-evaluators project-id)
)

;; Emergency withdrawal (only contract owner)
(define-public (emergency-withdraw (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
        (ok amount)
    )
)