# SPDX-License-Identifier: PMPL-1.0-or-later
# SOCP - Site Operations Control Plane
# Main init state

include:
  - socp.dns
  - socp.webserver
  - socp.php
  - socp.wordpress
  - socp.database
  - socp.cache
  - socp.security
