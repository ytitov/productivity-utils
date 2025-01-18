echo "
💡 Task champion setup:
1. create a client id: uuidgen
2. taskchampion server by default allows all client ids, unless configured to only allow certain ones so keep this in mind
3. add to your taskrc file:
      sync.server.url=https://taskwarrior.example.com
      🔹 current: 'sync.server.url': $(grep -ir 'sync.server.url' "$TASKRC")
      sync.server.client_id=[your client-id]
      sync.encryption_secret=[your encryption secret]

💡 Task configuration:
  🔹 'ENV.TASKDATA': $TASKDATA
  🔹 'ENV.TASKRC': $TASKRC
  🔹 'ENV.NOTES_DIR': $NOTES_DIR
  🔹 'cur.task': $(cur.task)

💡 Operating on a Task:
  🔹 'task.help' shows this message
  🔹 'task.show' shows the selected task and the related todos
  🔹 'task.select' selects a task to run other commands on like 'todo.add'
  🔹 'task.notes' launches editor with an attached markdown file you can write down your notes in
  🔹 'todo.add' adds a task with parentTaskId taken from first arg, adds a +todo tag
"
