#!/bin/bash
# E-Ren Production Setup Script
# Interactive Q&A style setup for migrations, categories, and admin account
#
# Usage: ./prod-setup.sh

set -e

NAMESPACE="${NAMESPACE:-default}"
RELEASE_NAME="${RELEASE_NAME:-e-ren}"

echo "═══════════════════════════════════════════════════════════"
echo "  E-Ren Production Setup"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check kubectl connection
if ! kubectl cluster-info &>/dev/null; then
  echo "ERROR: Cannot connect to Kubernetes cluster"
  echo "Make sure kubectl is configured correctly"
  exit 1
fi

# Get a running pod
POD=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=e-ren" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD" ]; then
  echo "ERROR: No e-ren pods found in namespace '$NAMESPACE'"
  echo "Make sure the app is deployed first with: helm install e-ren ."
  exit 1
fi

echo "Using pod: $POD"
echo ""

# Function to run rails command in pod
run_rails() {
  kubectl exec -n "$NAMESPACE" "$POD" -- bash -c "RAILS_ENV=production $1"
}

# ═══════════════════════════════════════════════════════════
#   Database Migrations
# ═══════════════════════════════════════════════════════════

echo "─────────────────────────────────────────────────────────"
echo "Step 1: Database Migrations"
echo "─────────────────────────────────────────────────────────"
read -p "Run database migrations? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Running migrations..."
  run_rails "bundle exec rails db:migrate"
  echo "✓ Migrations complete!"
else
  echo "Skipping migrations"
fi
echo ""

# ═══════════════════════════════════════════════════════════
#   Event Categories
# ═══════════════════════════════════════════════════════════

echo "─────────────────────────────────────────────────────────"
echo "Step 2: Default Event Categories"
echo "─────────────────────────────────────────────────────────"
echo "Will create:"
echo "  - Sports & Recreation"
echo "  - Social & Networking"
echo "  - Academic & Career"
echo "  - Food & Dining"
echo "  - Arts & Culture"
echo "  - Gaming & Esports"
echo ""
read -p "Create default event categories? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Creating categories..."
  run_rails "bundle exec rails runner \"
    categories = [
      'Sports & Recreation',
      'Social & Networking',
      'Academic & Career',
      'Food & Dining',
      'Arts & Culture',
      'Gaming & Esports'
    ]
    categories.each do |name|
      cat = EventCategory.find_or_create_by!(name: name)
      puts \\\"  Created: #{name}\\\"
    end
  \""
  echo "✓ Categories created!"
else
  echo "Skipping categories"
fi
echo ""

# ═══════════════════════════════════════════════════════════
#   Admin Account
# ═══════════════════════════════════════════════════════════

echo "─────────────────────────────────────────────────────────"
echo "Step 3: Admin Account"
echo "─────────────────────────────────────────────────────────"
read -p "Create admin account? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Get admin email
  read -p "Admin email (must be @wustl.edu): " ADMIN_EMAIL

  if [[ ! "$ADMIN_EMAIL" =~ @wustl\.edu$ ]]; then
    echo "WARNING: Email doesn't end with @wustl.edu"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Skipping admin creation"
      ADMIN_EMAIL=""
    fi
  fi

  if [ -n "$ADMIN_EMAIL" ]; then
    # Get admin password
    while true; do
      read -s -p "Admin password (min 8 chars): " ADMIN_PASSWORD
      echo ""

      if [ ${#ADMIN_PASSWORD} -lt 8 ]; then
        echo "Password must be at least 8 characters"
        continue
      fi

      read -s -p "Confirm password: " ADMIN_PASSWORD_CONFIRM
      echo ""

      if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
        echo "Passwords don't match, try again"
        continue
      fi

      break
    done

    echo "Creating admin account..."
    run_rails "bundle exec rails runner \"
      admin = User.find_or_initialize_by(email: '$ADMIN_EMAIL')
      admin.name = 'Admin'
      admin.password = '$ADMIN_PASSWORD'
      admin.password_confirmation = '$ADMIN_PASSWORD'
      admin.role = :super_admin
      admin.confirmed_at = Time.current
      admin.save!
      puts \\\"Admin created: $ADMIN_EMAIL\\\"
    \""
    echo "✓ Admin account created!"
  fi
else
  echo "Skipping admin account"
fi
echo ""

# ═══════════════════════════════════════════════════════════
#   Summary
# ═══════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Your app should now be ready at the ALB URL."
echo "Get the URL with:"
echo "  kubectl get ingress -n $NAMESPACE"
echo ""
