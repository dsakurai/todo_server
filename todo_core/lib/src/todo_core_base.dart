
// Put public facing types in this file.

class Todo_node {

  final List<Todo_node> children;
  String text;
  final String node_id;

  Map<String, Object?> to_map() {
    return {
      "children":  children,
      "text":    text,
      "hash": node_id,
    };
  }

  Todo_node(
    {
      this.text = "",
      children = const [],
      required this.node_id,
    }):
     children = List.from(children)
     ;
}
