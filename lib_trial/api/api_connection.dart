class ApiConnection {
  static const hostConnect = "http://192.168.1.3/backend";
  static const hostConnectAuth = "$hostConnect/api/auth";
  static const hostConnectCollab = "$hostConnect/api/collaborations";
  static const hostConnectFriends= "$hostConnect/api/friends";
  static const hostConnectNotes = "$hostConnect/api/notes";
  static const hostConnectReminder = "$hostConnect/api/reminders";
  static const hostConnectTasks = "$hostConnect/api/tasks";
  static const hostConnectTaskItems = "$hostConnect/api/task_item";

  static const signUp = "$hostConnectAuth/signup.php"; 
  static const validateEmail = "$hostConnectAuth/validate_email.php";
  static const login = "$hostConnectAuth/login.php";

  static const addTask = "$hostConnectTasks/add_tasks.php"; 
  static const deleteTask = "$hostConnectTasks/delete_tasks.php"; 
  static const getTask = "$hostConnectTasks/get_tasks.php"; 
  static const updateTask = "$hostConnectTasks/update_tasks.php";       

  static const addNote = "$hostConnectNotes/add_note.php";
  static const getNotes = "$hostConnectNotes/get_notes.php";
  static const updateNotes = "$hostConnectNotes/update_note.php";
  static const deleteNote = "$hostConnectNotes/delete_note.php";

  // Task Items API
static const addTaskItem = "$hostConnectTaskItems/add_task_item.php";
static const getTaskItems = "$hostConnectTaskItems/get_task_item.php";
static const updateTaskItem = "$hostConnectTaskItems/update_task_item.php";
static const deleteTaskItem = "$hostConnectTaskItems/delete_task_item.php";

static const getReminders = "$hostConnectReminder/get_reminders.php";
static const addReminder = "$hostConnectReminder/add_reminder.php";

static const assignTaskItem = "$hostConnectCollab/assign_task_item.php";

static const getSentCollabRequests = "$hostConnectCollab/get_collaborations.php";
static const sendCollaborationRequest = "$hostConnectCollab/send_collaboration_request.php";


  

}