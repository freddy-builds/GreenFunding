# GreenFunding

GreenFunding is an environmental grant allocation platform for eco-project financing and impact measurement built on the Stacks blockchain using Clarity smart contracts. The platform enables sustainable project funding through a transparent, decentralized system that connects environmental project creators with funders while ensuring accountability through impact tracking.

## Features

- **Project Submission**: Environmental project creators can submit detailed proposals with funding goals and impact metrics
- **Grant Approval Process**: Contract owner review and approval system for submitted projects
- **Decentralized Funding**: Anyone can fund approved projects using STX tokens
- **Impact Tracking**: Built-in system for tracking and reporting environmental impact metrics
- **Transparent Fund Management**: On-chain tracking of all contributions and fund withdrawals
- **Project Lifecycle Management**: Complete project status tracking from submission to completion
- **Multi-stakeholder Support**: Separate roles for project owners, funders, evaluators, and contract administrators
- **Emergency Controls**: Administrative functions for contract security and fund recovery

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity v2
- **Epoch**: 2.5
- **Network Compatibility**: Mainnet, Testnet, Devnet
- **Token Standard**: STX (native Stacks tokens)

## Architecture

The GreenFunding smart contract manages several key data structures:

### Project States
- **Pending** (0): Newly submitted projects awaiting review
- **Approved** (1): Projects approved for funding
- **Funded** (2): Projects that have reached their funding goal
- **Completed** (3): Projects marked as finished with impact reports
- **Rejected** (4): Projects rejected during review

### Data Storage
- **Projects Map**: Stores project details, funding status, and metadata
- **Grants Map**: Records all individual funding contributions
- **Project Funders Map**: Tracks per-user contributions to specific projects
- **User Contributions Map**: Maintains total contribution history per user
- **Project Evaluators Map**: Manages project evaluation assignments

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v16+
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd GreenFunding
```

2. Install dependencies:
```bash
cd GreenFunding_contract
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Submit a New Project

```clarity
(submit-project
    "Solar Community Garden"
    "Installing solar panels for sustainable community garden operations with year-round growing capability"
    u50000000  ;; 50 STX funding goal
    "renewable-energy"
    "Estimated 2.5 tons CO2 reduction annually, powers irrigation for 100 community garden plots")
```

### Approve a Project (Contract Owner Only)

```clarity
(approve-project u1)  ;; Approve project with ID 1
```

### Fund an Approved Project

```clarity
(fund-project
    u1                    ;; Project ID
    u10000000            ;; 10 STX contribution
    (some "Excited to support renewable energy in our community!"))
```

### Complete a Project

```clarity
(complete-project
    u1
    "Solar installation completed. Actual impact: 3.2 tons CO2 reduction in first year, 120 plots now powered")
```

### Withdraw Project Funds

```clarity
(withdraw-project-funds u1)  ;; Withdraw funds for project ID 1
```

## Contract Functions Documentation

### Read-Only Functions

| Function | Parameters | Description |
|----------|------------|-------------|
| `get-project` | `project-id: uint` | Retrieves project details by ID |
| `get-grant` | `grant-id: uint` | Retrieves grant details by ID |
| `get-project-funding` | `project-id: uint, funder: principal` | Gets user's contribution to specific project |
| `get-user-total-contributions` | `user: principal` | Returns user's total platform contributions |
| `get-total-funding` | - | Returns total platform funding amount |
| `get-project-count` | - | Returns total number of projects |
| `get-grant-count` | - | Returns total number of grants |
| `get-contract-owner` | - | Returns contract owner principal |
| `get-project-evaluators` | `project-id: uint` | Returns list of project evaluators |

### Public Functions

| Function | Parameters | Description | Access |
|----------|------------|-------------|---------|
| `submit-project` | `title, description, funding-goal, category, impact-metrics` | Submit new project for review | Anyone |
| `approve-project` | `project-id: uint` | Approve submitted project | Contract Owner |
| `reject-project` | `project-id: uint` | Reject submitted project | Contract Owner |
| `fund-project` | `project-id: uint, amount: uint, message: optional string` | Fund approved project | Anyone |
| `complete-project` | `project-id: uint, final-impact-report: string` | Mark project complete | Project Owner |
| `withdraw-project-funds` | `project-id: uint` | Withdraw project funding | Project Owner |
| `add-project-evaluator` | `project-id: uint, evaluator: principal` | Assign project evaluator | Contract Owner |
| `emergency-withdraw` | `amount: uint` | Emergency fund withdrawal | Contract Owner |

## Deployment Guide

### Local Development (Devnet)

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

3. Test contract functions:
```clarity
::get_contracts
(contract-call? .GreenFunding get-project-count)
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deployments generate --devnet
clarinet deployments apply --devnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

**Warning**: Ensure thorough testing on testnet before mainnet deployment.

## Security Notes

### Access Controls
- **Contract Owner**: Has exclusive rights to approve/reject projects, add evaluators, and perform emergency withdrawals
- **Project Owners**: Can only complete their own projects and withdraw their project funds
- **Funders**: Can fund any approved project but cannot withdraw contributions once made

### Fund Security
- All funding is held in the contract until withdrawal by project owners
- Project funds can only be withdrawn by the original project creator
- Emergency withdrawal function exists for contract owner in extreme circumstances
- STX transfers are validated and will revert on insufficient funds

### Validation Checks
- Projects must have positive funding goals
- Only approved projects can receive funding
- Funding cannot exceed project goals
- Project status transitions are strictly enforced
- All monetary amounts are validated for positive values

### Known Limitations
- No refund mechanism for funders if projects fail
- Project evaluators are assigned but evaluation logic not implemented in base contract
- No built-in dispute resolution mechanism
- Maximum 10 evaluators per project due to list size constraints

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `err-owner-only` | Function restricted to contract owner |
| 101 | `err-not-found` | Requested project or grant not found |
| 102 | `err-already-exists` | Resource already exists |
| 103 | `err-insufficient-funds` | Insufficient funds for operation |
| 104 | `err-invalid-amount` | Invalid amount specified |
| 105 | `err-project-not-active` | Project not in active/approved state |
| 106 | `err-unauthorized` | User not authorized for operation |
| 107 | `err-invalid-status` | Invalid project status transition |

## Testing

Run the test suite:
```bash
npm test
```

Run tests with coverage and cost analysis:
```bash
npm run test:report
```

Watch for changes and auto-run tests:
```bash
npm run test:watch
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with proper tests
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For technical support and questions, please create an issue in the project repository.