# Windows System Administration & PowerShell Repository

![License](https://img.shields.io/badge/license-MIT-green?style=plastic)
![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-blue?style=plastic)
![Windows](https://img.shields.io/badge/Platform-Windows%20Server-blue?style=plastic)
![Updated](https://img.shields.io/badge/Updated-2025-brightgreen?style=plastic)
![Enterprise](https://img.shields.io/badge/Enterprise-Ready-success?style=plastic)

## Overview

A comprehensive **Windows System Administration** and **PowerShell Scripting** repository showcasing enterprise-grade infrastructure management, Active Directory administration, database management, and cloud-native DevOps practices. This collection demonstrates production-ready automation scripts and administration patterns used in large-scale Windows environments.

**Perfect for:** Windows System Administrators, PowerShell engineers, Database administrators, DevOps professionals, and IT infrastructure specialists managing enterprise Windows ecosystems.

---
#### For PowerShell Scripting if you encounter an issue with being unable to run certain scripts, please change the execution policy, the information is specified below:
##### Change Execution Policy - [MS Docs](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.5)
---

## 📚 Repository Structure

```
Windows-System-Administration/
├── Active-Directory-Demo/         # Enterprise Identity Management
│   ├── CSV-Related-Scripts/       # Bulk user/group operations
│   ├── Group-Policy-Object-Demos/ # GPO configuration examples
│   ├── Account-Lockout/           # Security policies
│   ├── Password-Policy/           # Access control policies
│   └── Work-Logon-Hours/          # User access scheduling
│
├── Basic-PowerShell-Scripts/      # Foundation to Advanced PowerShell
│   ├── CSV-Related/               # CSV parsing & data import/export
│   ├── Common-PowerShell-Modules/ # Reusable utility modules
│   ├── PowerShell-DB-Scripts/     # Database operations
│   │   ├── MongoDB/               # NoSQL database management
│   │   ├── SQL-Server/            # Enterprise SQL Server admin
│   │   ├── SQLite/                # Lightweight database ops
│   │   └── Audit-Logging/         # Database audit trails
│   ├── PowerShell-GUI-Scripts/    # Windows Forms & GUI applications
│   ├── PowerShell-Logger-Demos/   # Logging & monitoring
│   └── User-Input/                # Interactive script design
│
├── Group-Policy-Object-Demos/     # Security & Configuration Management
│   ├── Security Policies
│   ├── Account Lockout
│   └── Password Requirements
│
├── Server-Config/                 # Windows Server Setup & Management
│   ├── Windows-Server-2019-Setup/ # 2019 configuration scripts
│   ├── Windows-Server-2022-Setup/ # 2022 configuration scripts
│   ├── Scripts-Config-Files/      # Configuration management
│   └── VM-Config/                 # Hyper-V VM management
│
├── Demos/                         # Real-World Scenarios
│   ├── IIS-And-FTP-Server-Demos/  # Web server setup
│   │   ├── FTP-Server/            # FTP configuration
│   │   └── WS2019-Demos/          # Windows Server 2019 examples
│   ├── Host-Static-Website-IIS/   # Static website hosting
│   └── SSH-Demo/                  # SSH server setup
│
└── README.md                      # This file
```

---

## 🚀 Key Features

### **PowerShell Automation Mastery**
- ✅ **Advanced PowerShell Programming:** Objects, functions, modules, error handling
- ✅ **CSV Data Processing:** Bulk import, filtering, transformation
- ✅ **Database Operations:** SQL Server, MongoDB, SQLite administration
- ✅ **GUI Development:** Windows Forms applications for system administration
- ✅ **Logging & Monitoring:** Comprehensive audit trails and event logging

### **Enterprise Active Directory**
- ✅ **Bulk User Management:** Creating users from CSV at scale
- ✅ **Group Policy Administration:** GPO creation and enforcement
- ✅ **Organizational Units:** OU structure and delegation
- ✅ **Access Control:** Security groups, permissions, role management
- ✅ **Account Security:** Lockout policies, password policies, MFA integration

### **Database Management**
- ✅ **SQL Server Administration:** T-SQL scripting, backup, recovery
- ✅ **MongoDB Operations:** NoSQL document management
- ✅ **SQLite Management:** Lightweight database operations
- ✅ **Data Backup & Recovery:** Automated backup scripts
- ✅ **Audit Logging:** Compliance and security audit trails

### **Windows Server Administration**
- ✅ **Server 2019 & 2022 Configuration:** Complete setup automation
- ✅ **IIS Web Server:** Website hosting, configuration, security
- ✅ **FTP Server Setup:** FTP service installation and management
- ✅ **SSH Server Setup:** Secure remote access configuration
- ✅ **Hyper-V VM Management:** Virtual machine provisioning and management

### **Security & Compliance**
- ✅ **Account Lockout Policies:** Brute force protection
- ✅ **Password Policies:** Complexity requirements and expiration
- ✅ **User Access Scheduling:** Time-based access control
- ✅ **Group Policy Security:** Comprehensive security enforcement
- ✅ **Audit Trail Management:** Compliance logging

---

## 📖 Quick Start

### **1. Clone the Repository**
```powershell
git clone https://github.com/Rohan-Personal-Repo/Windows-System-Admin-Tasks.git
cd Windows
```

### **2. Explore Basic PowerShell Scripts**
```powershell
# Navigate to scripts
cd Basic-PowerShell-Scripts

# Run a simple example
.\Create-User-From-CSV.ps1         # Bulk user creation
.\Create-UserAndDirectory.ps1       # Users with home directories
.\DisplayUserInfo.ps1               # Query user information
```

### **3. Explore Active Directory Administration**
```powershell
# Active Directory bulk operations
cd ..\Active-Directory-Demo\CSV-Related-Scripts

.\Create-AD-User-From-CSV.ps1       # Import users from CSV
.\Create-AD-User-Folder-From-CSV.ps1  # Create home directories
.\Create-AD-OU-Group-User-From-CSV.ps1 # Full OU/group/user setup
```

### **4. Database Operations**
```powershell
# SQL Server administration
cd ..\Basic-PowerShell-Scripts\PowerShell-DB-Scripts\SQL-Server

.\Connect-To-SQL-Server.ps1         # Database connectivity
.\Display-Data.ps1                  # Query and display data
.\SQL-CRUD-Operations.ps1           # Create, Read, Update, Delete

# MongoDB operations
cd ..\MongoDB
.\Display-Actor-Data-From-MongoDB.ps1  # Query MongoDB collections
.\Backup-Scripts                    # Backup and recovery
```

### **5. GUI Applications**
```powershell
# Launch Windows Forms GUI applications
cd ..\PowerShell-GUI-Scripts

.\Display-ActorData-From-MongoDB.ps1  # GUI MongoDB viewer
.\Display-Date-Time.ps1             # Interactive date/time display
.\Display-Emp-Data.ps1              # Employee data GUI
```

---

## 💡 Usage Examples

### **Active Directory: Bulk User Creation**
```powershell
# Create users from CSV file
cd Active-Directory-Demo\CSV-Related-Scripts
.\Create-AD-User-From-CSV.ps1
# Pass your CSV file with columns: FirstName, LastName, Username, Email, Department
```

**CSV Format Example:**
```
FirstName,LastName,Username,Email,Department
John,Doe,jdoe,jdoe@company.com,Engineering
Jane,Smith,jsmith,jsmith@company.com,Marketing
```

### **Group Policy: Apply Security Policies**
```powershell
# Apply password policy from Group Policy Objects
cd Group-Policy-Object-Demos
# Configure account lockout, password complexity requirements
```

### **Database: SQL Server Operations**
```powershell
# Connect and query SQL Server
cd Basic-PowerShell-Scripts\PowerShell-DB-Scripts\SQL-Server

.\Connect-To-SQL-Server.ps1
.\SQL-CRUD-Operations.ps1
# Execute INSERT, UPDATE, DELETE, SELECT operations
```

### **Database: MongoDB Operations**
```powershell
# Query MongoDB collections
cd PowerShell-DB-Scripts\MongoDB

.\Display-Actor-Data-From-MongoDB.ps1
.\Backup-Scripts\Backup-Issues.ps1
# Backup and manage MongoDB data
```

### **Server Configuration: IIS & FTP**
```powershell
# Set up web server
cd Demos\IIS-And-FTP-Server-Demos

# Configure IIS
.\WS2019-Demos              # Windows Server 2019 IIS setup

# Configure FTP Server
cd FTP-Server
# FTP installation and configuration
```

### **Logging: Comprehensive Audit Trails**
```powershell
# Set up event logging
cd Basic-PowerShell-Scripts\PowerShell-Logger-Demos

.\Script-With-Screenshots     # Capture operations with logs
# View audit trails and event logs
```

---

## 🎓 Learning Outcomes

After exploring this repository, you'll master:

| Topic | Skills Gained |
|-------|---|
| **PowerShell** | Advanced scripting, modules, functions, error handling |
| **Active Directory** | User management, group policy, organizational units |
| **Database Admin** | SQL Server, MongoDB, SQLite operations |
| **Windows Server** | 2019/2022 setup, IIS, FTP, SSH configuration |
| **Automation** | Bulk operations, CSV processing, scheduled tasks |
| **Compliance** | Audit logging, access control, security policies |
| **DevOps Basics** | Infrastructure as Code, configuration management |
| **GUI Development** | Windows Forms applications for system administration |

---

## 📊 Scripts Overview

| Category | Count | Use Case |
|----------|-------|----------|
| **Active Directory** | 15+ | Bulk user ops, group policy, security |
| **PowerShell Core** | 20+ | Scripting, functions, modules, logging |
| **Database Operations** | 25+ | SQL Server, MongoDB, SQLite, audit |
| **GUI Applications** | 8+ | Windows Forms interfaces, user interaction |
| **Server Configuration** | 12+ | IIS, FTP, SSH, Windows Server setup |
| **Networking** | 5+ | FTP, SSH, connectivity, security |

---

## 🔒 Security Best Practices

This repository includes enterprise security implementations. When using these scripts:

- ⚠️ **Validate CSV inputs** - Check data before bulk import
- ⚠️ **Use strong policies** - Enforce password complexity
- ⚠️ **Audit everything** - Track administrative changes
- ⚠️ **Control access** - Use role-based access control (RBAC)
- ⚠️ **Test in staging** - Validate in non-production first
- ⚠️ **Encrypt credentials** - Never hardcode passwords
- ⚠️ **Monitor logs** - Regular review of security events

---

## 🛠️ Technologies Used

- **PowerShell 7.0+** - Modern scripting and automation
- **Active Directory** - Enterprise identity management
- **SQL Server** - Relational database management
- **MongoDB** - NoSQL document database
- **IIS** - Internet Information Services
- **FTP/SSH** - Remote access protocols
- **Windows Forms** - Windows Forms for GUI
- **Windows Server 2019/2022** - Enterprise OS

---

## 📋 Advanced Topics Covered

- ✅ PowerShell Object-Oriented Programming
- ✅ Error Handling & Try-Catch Patterns
- ✅ Module Development & Distribution
- ✅ Active Directory Replication
- ✅ Group Policy Management (GPO)
- ✅ Database Backup & Recovery
- ✅ Audit Trail Compliance
- ✅ Performance Monitoring
- ✅ Security Hardening

---

## 📝 License

This project is licensed under the **MIT License** - see LICENSE file for details.

---

## 🎯 Next Steps

**Want to master Windows Administration?**

1. **Study each script category** - Understand components
2. **Test in your environment** - Adapt to your needs
3. **Create production scripts** - Build custom automation
4. **Implement security** - Deploy in secure manner
5. **Pursue DevOps roles** - Use for infrastructure engineering

---

## 💼 Enterprise Readiness

This repository is designed for enterprise production use:

- ✅ Scalable architecture
- ✅ Error handling and recovery
- ✅ Logging and audit trails
- ✅ Security best practices
- ✅ Active Directory integration
- ✅ Database transaction safety
- ✅ Compliance-ready features

---

## 📞 Connect & Support

**Have questions or need help?**
- 🔗 GitHub: [@Rohan-Repo](https://github.com/Rohan-Repo)
- 💼 Looking for collaboration on enterprise infrastructure
---

## 🌟 Repository Stats

- **Last Updated:** December 2025
- **PowerShell Scripts:** 60+
- **Database Scripts:** 25+
- **GUI Applications:** 8+
- **Total Lines of Code:** 5,000+
- **Categories:** 8 major areas
- **Skill Level:** Intermediate to Advanced

---

**⭐ If you find this repository helpful, please star it! It helps other Windows professionals discover these resources.**

---

## 🔗 Related Repositories

- **Linux System Administration** - Bash scripting, shell administration, security : 
[Linux-System-Administration](https://github.com/Rohan-Repo/Linux-System-Administration-Tasks)
- **Backend Development** - Spring Boot, Microservices, Cloud-Native Applications
[SpringBoot-Codebase](https://github.com/Rohan-Repo/Spring-Boot-Codebase)
- **Database Management** - Advanced SQL, MongoDB : 
[SQL-Codebase](https://github.com/Rohan-Repo/SQL-Codebase)
[MongoDB-Codebase](https://github.com/Rohan-Repo/MongoDB-Crash-Course)
- **Python Beginner to Intermediate** - Python Core, Data Analysis, Web Development
[Python-Codebase](https://github.com/Rohan-Repo/Python-Codebase/)
- **Java Beginner to Intermediate** - Core Java Fundamentals 
[Java-Codebase](https://github.com/Rohan-Repo/Java-Codebase)

---

**Built with ❤️ for the Windows community. Happy scripting!**

