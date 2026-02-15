# Feature Specification: Secure Remote Access Setup

**Feature Branch**: `004-secure-remote-access`  
**Created**: 2026-02-15  
**Status**: Draft  
**Input**: User description: "A user wants to allow access to their FoundryVTT instance remotely. Guide them through the process of setting up remote access with HTTPS security. Cloudflare tunnels (or something like that) will allow for access without complex firewall rules and be able to be used by the user wherever they are. If they are traveling and the host is with them, they are on a guest wifi network, this still works."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set Up Secure Remote Access (Priority: P1)

A user wants their players to connect to their FoundryVTT game from anywhere on the internet. They run the remote access script, which guides them through setting up a secure tunnel service. Once complete, they receive a URL they can share with their players. The connection is encrypted (HTTPS) and works without the user needing to configure their router or firewall.

**Why this priority**: This is the core value—enabling remote play. Without this, users are limited to local network games only.

**Independent Test**: Can be fully tested by setting up the tunnel, then accessing FoundryVTT from a device on a different network (e.g., mobile data) using the provided URL.

**Acceptance Scenarios**:

1. **Given** a working FoundryVTT installation (from feature 001), **When** the user runs the remote access setup script, **Then** they are guided through creating a secure tunnel with a shareable URL.

2. **Given** remote access is configured, **When** a player visits the provided URL from any internet connection, **Then** they can access the FoundryVTT login page over HTTPS.

3. **Given** the setup completes, **When** the user checks the connection, **Then** they see confirmation that HTTPS is active and the connection is secure.

---

### User Story 2 - Portable Remote Access (Priority: P2)

A user is traveling with their gaming laptop (Steam Deck, etc.) and connects to a hotel or coffee shop WiFi. They want to host a game session for their remote players. Without any additional configuration, the secure tunnel works from this new network—players connect using the same URL as always.

**Why this priority**: This is the key differentiator of tunnel-based access. Traditional port forwarding breaks when changing networks; tunnels don't.

**Independent Test**: Can be tested by setting up remote access on one network, moving to a different network, and verifying players can still connect using the same URL.

**Acceptance Scenarios**:

1. **Given** remote access was configured on the user's home network, **When** the user connects to a different network (hotel, cafe, mobile hotspot), **Then** remote access continues to work without reconfiguration.

2. **Given** the user is on a restrictive guest network, **When** FoundryVTT starts with remote access enabled, **Then** players can still connect via the tunnel URL.

---

### User Story 3 - Manage Remote Access (Priority: P3)

A user wants to control when their FoundryVTT instance is accessible remotely. They can enable or disable remote access, check its current status, and view the access URL. When disabled, FoundryVTT is only accessible on the local network.

**Why this priority**: Security and control feature. Users should be able to limit exposure when not actively hosting remote sessions.

**Independent Test**: Can be tested by toggling remote access on/off and verifying external accessibility changes accordingly.

**Acceptance Scenarios**:

1. **Given** remote access is enabled, **When** the user runs the script with a disable option, **Then** the tunnel stops and external access is blocked.

2. **Given** remote access is disabled, **When** the user runs the script with an enable option, **Then** the tunnel starts and the access URL is displayed.

3. **Given** remote access is configured, **When** the user checks status, **Then** they see whether it's currently active and the URL if enabled.

---

### Edge Cases

- What happens when the user doesn't have an account with the tunnel service?
  - The script guides them through creating a free account and provides clear instructions for each step.

- What happens when the tunnel service is unavailable or rate-limited?
  - The script detects connection issues and provides troubleshooting guidance, including checking service status.

- What happens when the user's internet connection is too slow or unstable?
  - The script warns about potential performance issues and suggests minimum bandwidth requirements for a good experience.

- What happens when remote access is enabled but FoundryVTT isn't running?
  - The tunnel may start, but players see a connection error. The script should warn if FoundryVTT isn't detected as running.

- What happens when the user wants to change their access URL or domain?
  - The script provides options to reconfigure the tunnel with different settings.

- What happens when multiple users try to set up tunnels on the same account?
  - The script detects existing tunnel configurations and offers to reuse or replace them.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The script MUST guide users through setting up a secure tunnel service for remote access.

- **FR-002**: The script MUST configure HTTPS encryption for all remote connections (no unencrypted access).

- **FR-003**: The script MUST provide users with a shareable URL for remote access.

- **FR-004**: The script MUST work without requiring router/firewall configuration (NAT traversal via tunnel).

- **FR-005**: The script MUST allow users to enable or disable remote access on demand.

- **FR-006**: The script MUST display current remote access status (enabled/disabled, URL if active).

- **FR-007**: The script MUST persist remote access configuration so it survives system restarts.

- **FR-008**: The script MUST optionally configure remote access to start automatically with FoundryVTT.

- **FR-009**: The script MUST validate that FoundryVTT is accessible locally before enabling remote access.

- **FR-010**: The script MUST provide clear error messages and troubleshooting guidance when tunnel setup fails.

- **FR-011**: The script MUST work on restrictive networks (hotel WiFi, guest networks, mobile hotspots) without additional configuration.

- **FR-012**: The script MUST guide users through tunnel service account creation if they don't have one.

### Key Entities

- **Secure Tunnel**: The encrypted connection between the user's FoundryVTT instance and the tunnel service. Enables remote access without port forwarding.

- **Access URL**: The public URL players use to connect to FoundryVTT. Provided by the tunnel service, remains consistent across network changes.

- **Tunnel Configuration**: Stored settings for the tunnel service (account credentials, tunnel ID, auto-start preference). Persists across restarts.

- **Tunnel Service Account**: User's account with the tunnel provider (e.g., Cloudflare). Required for tunnel creation and management.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can set up secure remote access in under 15 minutes, including account creation if needed.

- **SC-002**: Remote players can connect to FoundryVTT via the provided URL within 30 seconds of the tunnel being active.

- **SC-003**: All remote connections use HTTPS encryption (no option for unencrypted access).

- **SC-004**: Remote access works from any network without additional configuration (tested on at least 3 different network types: home, mobile hotspot, public WiFi).

- **SC-005**: 90% of users successfully complete remote access setup on their first attempt.

- **SC-006**: Users can enable/disable remote access in under 10 seconds.

## Assumptions

- Users have a working FoundryVTT installation from the setup script (feature 001).
- A free tier of the tunnel service is sufficient for typical FoundryVTT usage (small number of concurrent players).
- Users have an email address for creating a tunnel service account if needed.
- The tunnel service remains available and maintains its free tier (documented as external dependency).
- Internet bandwidth requirements are communicated to users (tunnel adds minimal overhead, but remote play requires decent upload speed).
- The access URL may be a subdomain of the tunnel service (e.g., `something.trycloudflare.com`) unless the user configures a custom domain.
