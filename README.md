# Renewable Resource Tracking Platform

A comprehensive blockchain-based platform for tracking and trading renewable resources including water credits, forest conservation certificates, and biodiversity tokens. The system enables transparent environmental impact measurement, conservation project funding, and sustainable resource marketplace operations.

## 🌱 Overview

This platform addresses the growing need for transparent, verifiable environmental resource management through blockchain technology. It provides tools for:

- **Conservation Project Registration & Verification**: Manage environmental conservation projects with transparent verification processes
- **Resource Credit Trading**: Facilitate trading of water credits, forest certificates, and biodiversity tokens
- **Environmental Impact Measurement**: Track biodiversity and ecosystem health metrics
- **Compliance & Reporting**: Support corporate environmental compliance through resource purchases
- **Sustainable Finance**: Enable conservation project funding through marketplace revenues

## 📋 Smart Contracts

### Conservation Project Registry (`conservation-project-registry.clar`)
Manages the core registration and verification system for environmental conservation projects:

- **Project Registration**: Register new conservation projects with detailed metadata
- **Verification System**: Multi-stage verification process for project authenticity
- **Credit Issuance**: Issue renewable resource credits based on verified conservation activities
- **Biodiversity Tracking**: Monitor ecosystem health metrics and biodiversity scores
- **Sponsor Management**: Track funding relationships between sponsors and projects
- **Impact Reporting**: Generate transparent environmental impact reports

### Resource Trading Marketplace (`resource-trading-marketplace.clar`)
Facilitates the trading ecosystem for renewable resource credits:

- **Multi-Asset Trading**: Support for water credits, forest certificates, and biodiversity tokens
- **Automated Price Discovery**: Bonding-curve based pricing for transparent market operations
- **Purchase & Settlement**: Streamlined transaction processing for credit purchases
- **Compliance Retirement**: Handle environmental offset retirement for compliance claims
- **Project Funding Distribution**: Channel marketplace revenues to conservation projects
- **Sustainability Reporting**: Integration with corporate sustainability reporting systems

## 🚀 Getting Started

### Prerequisites
- [Clarinet CLI](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Git](https://git-scm.com/) for version control

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/dmojisola848/renewable-resource-tracking.git
   cd renewable-resource-tracking
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Verify installation:
   ```bash
   clarinet check
   ```

### Development Workflow
1. **Contract Development**: Contracts are located in the `contracts/` directory
2. **Testing**: Test files are in the `tests/` directory using Clarinet's testing framework
3. **Configuration**: Project settings are managed in `Clarinet.toml`

### Running Tests
```bash
clarinet test
```

### Local Development Network
```bash
clarinet integrate
```

## 🏗️ Architecture

### Data Flow
1. **Project Registration**: Conservation projects register through the registry contract
2. **Verification Process**: Multi-stakeholder verification of project credentials
3. **Credit Issuance**: Verified projects receive tradeable resource credits
4. **Marketplace Trading**: Credits are listed and traded on the marketplace
5. **Compliance & Retirement**: Corporate buyers retire credits for compliance reporting

### Key Features
- **Transparent Verification**: All project data and verification steps are recorded on-chain
- **Automated Pricing**: Market-driven price discovery through bonding curve mechanisms
- **Multi-Asset Support**: Unified platform for different types of environmental credits
- **Compliance Integration**: Built-in support for regulatory compliance requirements
- **Funding Flow**: Direct connection between marketplace revenue and project funding

## 🔧 Configuration

### Clarinet Configuration (`Clarinet.toml`)
The project is configured to work with Stacks blockchain testnet and mainnet deployments.

### Package Configuration (`package.json`)
Includes all necessary dependencies for development and testing.

## 🧪 Testing

The project includes comprehensive testing for:
- Project registration and verification flows
- Credit issuance and tracking
- Marketplace trading operations
- Price discovery mechanisms
- Compliance and retirement processes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Ensure all tests pass (`clarinet check && clarinet test`)
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines
- Follow existing code patterns and naming conventions
- Add comprehensive tests for new functionality
- Update documentation for any public API changes
- Ensure all contracts pass `clarinet check` without warnings

## 📊 Environmental Impact

This platform directly supports:
- **Carbon Offset Programs**: Through forest conservation certificates
- **Water Conservation**: Via tradeable water credits
- **Biodiversity Protection**: Using biodiversity tokens for ecosystem preservation
- **Sustainable Finance**: Directing capital to verified environmental projects

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌍 Vision

Our goal is to create a transparent, efficient, and scalable system for environmental resource management that:
- Accelerates funding for conservation projects
- Provides verifiable environmental impact data
- Supports corporate sustainability goals
- Promotes ecosystem preservation through market mechanisms

---

**Built with ❤️ for the environment using Stacks blockchain technology**