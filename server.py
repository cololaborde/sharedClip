from flask import Flask, request, jsonify

app = Flask(__name__)
clipboard_content = ""

@app.route("/get", methods=["GET"])
def get_clipboard():
    return jsonify({"content": clipboard_content})

@app.route("/set", methods=["POST"])
def set_clipboard():
    global clipboard_content
    clipboard_content = request.json.get("content", "")
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
