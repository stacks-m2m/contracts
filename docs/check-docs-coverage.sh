#!/bin/bash

# Exit on any error
set -e

echo "🔍 Checking docs coverage for Clarity contracts..."
echo "================================================"

# Initialize counters
total_contracts=0
undocumented_contracts=0

# Function to convert contract path to expected doc path
get_doc_path() {
    local contract_path=$1
    # Remove 'contracts/' prefix and replace with 'docs/'
    # Replace .clar with .md
    echo "${contract_path/contracts\//docs\/}" | sed 's/\.clar$/.md/'
}

# Debug: Print current directory
echo "Running from directory: $(pwd)"
echo "Looking for .clar files..."

# Find all Clarity contracts and store in array
contracts=()
echo "Finding Clarity contracts..."
echo "Excluding test contracts and DAO traits..."
while IFS= read -r contract; do
    contracts+=("$contract")
done < <(find contracts -name "*.clar" -not -path "contracts/test/*" -not -path "contracts/dao/traits/*")

echo "Found ${#contracts[@]} contract files"

# Check if any contracts were found
if [ ${#contracts[@]} -eq 0 ]; then
    echo "❌ No .clar files found in the contracts directory!"
    echo "   Please make sure you're running this script from the project root."
    exit 1
fi

# Process each contract
echo -e "\nChecking docs coverage..."
echo "=========================="
for contract in "${contracts[@]}"; do
    let "total_contracts=total_contracts+1"
    doc_file=$(get_doc_path "$contract")
    
    if [ ! -f "$doc_file" ]; then
        echo "❌ Missing doc file for: $contract"
        echo "   Expected doc at: $doc_file"
        let "undocumented_contracts=undocumented_contracts+1"
    else
        echo "✅ Found doc for: $contract"
    fi
done

# Print summary
echo ""
echo "📊 Summary"
echo "=========="
echo "Total contracts found: $total_contracts"
echo "Contracts with docs: $(($total_contracts - $undocumented_contracts))"
echo "Contracts without docs: $undocumented_contracts"
echo ""

if [ $undocumented_contracts -eq 0 ]; then
    echo "✅ All contracts have corresponding documentation files"
    exit 0
else
    echo "❌ Action needed: $undocumented_contracts contract(s) are missing docs"
    exit 1
fi