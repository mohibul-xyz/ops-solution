#!/bin/bash
# Terraform OPA Policy Validation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAC_DIR="$(dirname "$SCRIPT_DIR")"
POLICIES_DIR="$IAC_DIR/policies"
PLAN_FILE="${1:-tfplan.json}"

echo "==================================="
echo "Terraform OPA Policy Validation"
echo "==================================="
echo ""

# Check if OPA is installed
if ! command -v opa &> /dev/null; then
    echo "ERROR: OPA is not installed. Please install OPA first."
    echo "Installation: https://www.openpolicyagent.org/docs/latest/#running-opa"
    exit 1
fi

# Check if plan file exists
if [ ! -f "$PLAN_FILE" ]; then
    echo "ERROR: Terraform plan file not found: $PLAN_FILE"
    echo "Usage: $0 <path-to-tfplan.json>"
    exit 1
fi

echo "Plan file: $PLAN_FILE"
echo "Policies directory: $POLICIES_DIR"
echo ""

# Run OPA evaluation for each policy package
echo "Running OPA policy checks..."
echo ""

# Check terraform policies
echo "--- Terraform Best Practices ---"
TERRAFORM_RESULT=$(opa eval --data "$POLICIES_DIR/terraform.rego" --input "$PLAN_FILE" --format pretty "data.terraform.deny" 2>&1) || true
if [ -n "$TERRAFORM_RESULT" ] && [ "$TERRAFORM_RESULT" != "[]" ]; then
    echo "❌ VIOLATIONS FOUND:"
    echo "$TERRAFORM_RESULT"
    VIOLATIONS=true
else
    echo "✅ No violations"
fi
echo ""

# Check warnings
TERRAFORM_WARNINGS=$(opa eval --data "$POLICIES_DIR/terraform.rego" --input "$PLAN_FILE" --format pretty "data.terraform.warn" 2>&1) || true
if [ -n "$TERRAFORM_WARNINGS" ] && [ "$TERRAFORM_WARNINGS" != "[]" ]; then
    echo "⚠️  WARNINGS:"
    echo "$TERRAFORM_WARNINGS"
fi
echo ""

# Check cost control policies
echo "--- Cost Control Policies ---"
COST_RESULT=$(opa eval --data "$POLICIES_DIR/cost_control.rego" --input "$PLAN_FILE" --format pretty "data.terraform.cost.deny" 2>&1) || true
if [ -n "$COST_RESULT" ] && [ "$COST_RESULT" != "[]" ]; then
    echo "❌ VIOLATIONS FOUND:"
    echo "$COST_RESULT"
    VIOLATIONS=true
else
    echo "✅ No violations"
fi
echo ""

# Check cost warnings
COST_WARNINGS=$(opa eval --data "$POLICIES_DIR/cost_control.rego" --input "$PLAN_FILE" --format pretty "data.terraform.cost.warn" 2>&1) || true
if [ -n "$COST_WARNINGS" ] && [ "$COST_WARNINGS" != "[]" ]; then
    echo "⚠️  WARNINGS:"
    echo "$COST_WARNINGS"
fi
echo ""

# Check security policies
echo "--- Security Policies ---"
SECURITY_RESULT=$(opa eval --data "$POLICIES_DIR/security.rego" --input "$PLAN_FILE" --format pretty "data.terraform.security.deny" 2>&1) || true
if [ -n "$SECURITY_RESULT" ] && [ "$SECURITY_RESULT" != "[]" ]; then
    echo "❌ VIOLATIONS FOUND:"
    echo "$SECURITY_RESULT"
    VIOLATIONS=true
else
    echo "✅ No violations"
fi
echo ""

# Check security warnings
SECURITY_WARNINGS=$(opa eval --data "$POLICIES_DIR/security.rego" --input "$PLAN_FILE" --format pretty "data.terraform.security.warn" 2>&1) || true
if [ -n "$SECURITY_WARNINGS" ] && [ "$SECURITY_WARNINGS" != "[]" ]; then
    echo "⚠️  WARNINGS:"
    echo "$SECURITY_WARNINGS"
fi
echo ""

# Summary
echo "==================================="
echo "Summary"
echo "==================================="

if [ "$VIOLATIONS" = true ]; then
    echo "❌ Policy validation FAILED - violations found"
    exit 1
else
    echo "✅ Policy validation PASSED - no violations"
    exit 0
fi

