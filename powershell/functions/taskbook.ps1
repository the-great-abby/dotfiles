Write-Output "
============================
Taskbook PS1 Functions Loaded
============================
"
function taskbook_note_create {
  param
  (
      [Parameter(Mandatory=$true)] $_note_text
  )
  tb -n ${note_text}

}
function taskbook_task_create {
  param
  (
      [Parameter(Mandatory=$true)] $_task
  )
   tb -t ${_task}
}

function taskbook_board_create {
  param
  (
      [Parameter(Mandatory=$true)] $_board,
      [Parameter(Mandatory=$true)] $_item
  )
  tb -t "@${_board} ${_item}"
}
function taskbook_task_check {
  param
  (
      [Parameter(Mandatory=$true)] $_task_id
  )
  tb -c ${_task_id}
}
function taskbook_task_begin {
  param
  (
      [Parameter(Mandatory=$true)] $_task_id
  )
  tb -b ${_task_id}
}
function taskbook_task_star {
  param
  (
      [Parameter(Mandatory=$true)] $_task_id
  )
  tb -s ${_task_id}
}

function taskbook_board_display {
  tb
}

function taskbook_timeline_display {
  tb -i
}
function taskbook_task_clear_checked {
  tb --clear
}
function taskbook_task_create_with_priority {
  param
  (
      [Parameter(Mandatory=$true)] $_board,
      [Parameter(Mandatory=$true)] $_item,
      [Parameter(Mandatory=$true)] $_priority
  )
  tb -t "@${_board} ${_item} p:${_priority}"
}

function taskbook_items_search {
  param
  (
      [Parameter(Mandatory=$true)] $_search_string
  )
    tb -f ${_search_string}
    Write-Output "
    tb -f ${_search_string}
    "
}
function taskbook_items_move {
  param($task_id, $board)
  param
  (
      [Parameter(Mandatory=$true)] $_task_id,
      [Parameter(Mandatory=$true)] $_board
  )
  tb -m "@${_task_id} ${_board}"
}
function taskbook_board_item_list  {
  param
  (
      [Parameter(Mandatory=$true)] ${_board}
  )
    tb -l ${_board}
    Write-Output "
    myboard - Items that belong to My board
    task, tasks, todo - Items that are tasks.
    note, notes - Items that are notes.
    pending, unchecked, incomplete - Items that are pending tasks.
    progress, started, begun - Items that are in-progress tasks.
    done, checked, complete - Items that complete tasks.
    star, starred - Items that are starred.
    "
}


