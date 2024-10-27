
// Put public facing types in this file.


enum GTD_tag {
  Now,
  Waiting,
  Someday,
  Context,
  Reference
}

class Task {
  String text;
  GTD_tag gtd_tag;

  Map<String, Object?> to_map() {
    return {
      "text" : text,
      "gtd_tag": gtd_tag.name
    };
  }

  Task (
    {this.text    = "",
     this.gtd_tag = GTD_tag.Now
    }
  );
}

class Todo_value {

  String group; // Used for creating, e.g., a "Private" group
  String project;
  final Task? task; // null means that this is a database store to save just a group or project name.

  Map<String, Object?> to_map() {
    return {
      "group":   group,
      "project": project,
      "task":    task?.to_map(),
    };
  }

  Todo_value(
    {
      this.group   = "",
      this.project = "",
      this.task,
    }
  );
}
