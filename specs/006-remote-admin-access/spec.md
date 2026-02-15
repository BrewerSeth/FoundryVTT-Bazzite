# Feature Specification: Remote System Administration Access

**Feature Branch**: `006-remote-admin-access`  
**Created**: 2026-02-15  
**Status**: Draft  
**Input**: User description: "The user wants the option for remote access to the services behind the scenes. Remote access to the Bazzite system using technologies like Tailscale could be used."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set Up Remote Admin Access (Priority: P1)

A user wants to manage their Bazzite system remotely—perhaps they're away from home but need to restart FoundryVTT, check logs, run maintenance scripts, or troubleshoot issues. They run a setup script that configures a private mesh network (like Tailscale), allowing them to securely connect to their system from anywhere using their phone, laptop, or another computer.

**Why this priority**: This is the core feature—enabling secure remote administration. Without this, users must be physically present to manage their system.

**Independent Test**: Can be fully tested by setting up remote access, then connecting from a different network (mobile data, different WiFi) and successfully running admin commands.

**Acceptance Scenarios**:

1. **Given** a Bazzite system with FoundryVTT installed, **When** the user runs the remote admin setup script, **Then** they are guided through configuring secure mesh network access.

2. **Given** remote admin is configured, **When** the user connects from a remote device on the same mesh network, **Then** they can access the system's command line securely.

3. **Given** the setup completes, **When** the user views their connection info, **Then** they see the private network address and connection status.

---

### User Story 2 - Access FoundryVTT Admin Remotely (Priority: P2)

A user is away from home and needs to access their FoundryVTT instance directly—perhaps to access the setup screen, configure settings, or manage the game while not on their local network. Through the private mesh network, they can reach FoundryVTT's web interface using an internal address, without exposing it to the public internet.

**Why this priority**: Directly complements the core feature—remote system access is most useful when it enables access to the services running on that system.

**Independent Test**: Can be tested by connecting to the mesh network from a remote device and accessing FoundryVTT's web interface via the private network address.

**Acceptance Scenarios**:

1. **Given** remote admin access is configured, **When** the user connects to their mesh network from a remote device, **Then** they can access FoundryVTT's web interface via the private network address.

2. **Given** multiple FoundryVTT instances are running (feature 005), **When** the user connects remotely, **Then** they can access each instance on its respective port.

3. **Given** the user is on the mesh network, **When** they access FoundryVTT, **Then** the connection is private (not exposed to the public internet).

---

### User Story 3 - Manage Remote Access (Priority: P3)

A user wants to control their remote admin access—view connection status, see which devices are authorized, enable/disable remote access, or revoke access for a lost device. The script provides commands to manage the mesh network configuration.

**Why this priority**: Security management feature. Users need control over who can access their system remotely.

**Independent Test**: Can be tested by checking status, adding/removing devices, and verifying access changes take effect.

**Acceptance Scenarios**:

1. **Given** remote admin is configured, **When** the user checks status, **Then** they see whether remote access is active and which devices are authorized.

2. **Given** remote admin is enabled, **When** the user disables it, **Then** remote connections are no longer accepted.

3. **Given** a device was previously authorized, **When** the user revokes its access, **Then** that device can no longer connect.

---

### Edge Cases

- What happens when the user doesn't have an account with the mesh network service?
  - The script guides them through creating a free account and provides clear instructions.

- What happens when the mesh network service is unavailable?
  - The script detects connection issues and provides troubleshooting guidance.

- What happens when the user tries to connect from an unauthorized device?
  - The connection is rejected. The user must authorize the device through their mesh network account.

- What happens when the user's Bazzite system goes offline?
  - Remote access is unavailable until the system comes back online. This is expected behavior.

- What happens when remote access conflicts with the public tunnel (feature 004)?
  - Both can coexist—public tunnel is for players, private mesh is for admin. They serve different purposes.

- What happens when the user forgets their mesh network credentials?
  - The script provides guidance on account recovery through the mesh network provider.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The script MUST guide users through setting up a private mesh network for remote system access.

- **FR-002**: The script MUST configure secure, encrypted connections for all remote admin traffic.

- **FR-003**: The script MUST provide the user with their private network address for remote connections.

- **FR-004**: The script MUST allow users to enable or disable remote admin access.

- **FR-005**: The script MUST display current remote access status (enabled/disabled, connected devices).

- **FR-006**: The script MUST allow remote access to FoundryVTT instances via their private network addresses.

- **FR-007**: The script MUST allow remote command-line access for running maintenance scripts.

- **FR-008**: The script MUST persist configuration so remote access survives system restarts.

- **FR-009**: The script MUST optionally configure remote access to start automatically on boot.

- **FR-010**: The script MUST provide guidance on authorizing new devices to the mesh network.

- **FR-011**: The script MUST coexist with public player access (feature 004) without conflicts.

- **FR-012**: The script MUST provide clear error messages and troubleshooting guidance when connection issues occur.

### Key Entities

- **Mesh Network**: Private encrypted network connecting the user's devices. Only authorized devices can join and communicate.

- **Private Network Address**: The internal address assigned to the Bazzite system on the mesh network. Used to access services remotely.

- **Authorized Devices**: Devices the user has approved to join their mesh network. Only these can connect to the Bazzite system remotely.

- **Remote Session**: An active connection from an authorized device to the Bazzite system over the mesh network.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can set up remote admin access in under 15 minutes, including account creation if needed.

- **SC-002**: Users can connect to their system from any internet connection within 30 seconds of initiating connection.

- **SC-003**: All remote admin connections are encrypted (no unencrypted admin access option).

- **SC-004**: Remote access works regardless of network configuration (NAT, firewalls, etc.) on either end.

- **SC-005**: Users can access FoundryVTT's web interface and run maintenance scripts remotely.

- **SC-006**: Remote admin access and public player access (feature 004) can operate simultaneously without conflict.

## Assumptions

- Users have an email address for creating a mesh network account if needed.
- A free tier of the mesh network service is sufficient for personal admin use (small number of devices).
- Remote admin access is for the system owner only—this is not for sharing admin access with others.
- The mesh network client can run on the Bazzite system (either on host or in container).
- Users understand that remote access requires their Bazzite system to be powered on and connected to the internet.
- This feature provides private access for administration; public player access remains handled by feature 004.
- SSH or terminal access is the primary use case for command-line administration.
