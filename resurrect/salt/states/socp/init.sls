# SPDX-License-Identifier: MPL-2.0
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
