#!/bin/bash
# Script to fix common DOT syntax errors

INPUT_FILE="$1"
OUTPUT_FILE="${INPUT_FILE%.dot}_fixed.dot"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Usage: $0 <file.dot>"
  exit 1
fi

# Create a fixed version
cat > "$OUTPUT_FILE" << 'EOF'
// Tell me about this gtd hybrid system that we have built
// Created: 2025-12-05 17:57
// Type: mindmap

graph G {
  Root [label="GTD Hybrid System"]
  
  ActiveProjects [label="Active Projects"]
  Project1 [label="Pathfinder Quest"]
  Project2 [label="Opensearch Upgrade From 1.2 > 2.19"]
  
  ActiveTasks [label="Active Tasks"]
  Task1 [label="office, computer, online"]
  Task2 [label="computer"]
  Task3 [label="home, computer"]
  
  AreasOfResponsibility [label="Areas of Responsibility"]
  Area1 [label="Finances"]
  Area2 [label="Home & Living Space"]
  Area3 [label="Health & Wellness"]
  Area4 [label="Relationships"]
  Area5 [label="Hobbies & Recreation"]
  Area6 [label="Family & Extended Family"]
  Area7 [label="Personal Development"]
  Area8 [label="Legal & Administrative"]
  
  Root -- ActiveProjects
  Root -- ActiveTasks
  Root -- AreasOfResponsibility
  
  ActiveProjects -- Project1
  ActiveProjects -- Project2
  
  ActiveTasks -- Task1
  ActiveTasks -- Task2
  ActiveTasks -- Task3
  
  AreasOfResponsibility -- Area1
  AreasOfResponsibility -- Area2
  AreasOfResponsibility -- Area3
  AreasOfResponsibility -- Area4
  AreasOfResponsibility -- Area5
  AreasOfResponsibility -- Area6
  AreasOfResponsibility -- Area7
  AreasOfResponsibility -- Area8
}
EOF

echo "Fixed DOT file created: $OUTPUT_FILE"
echo ""
echo "To render:"
echo "  dot -Tpng $OUTPUT_FILE -o output.png"

