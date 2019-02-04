
import sys
from flask import Flask
import json

app = Flask(__name__)


def load_file_to_json(filename):
    with open(filename) as json_file:
        return json.load(json_file)


@app.route('/details/<product_id>')
def get_all_purchases(product_id):

    # This is a backdoor used by developers to get all purchase details for testing purposes. Was left open in prod.
    details_json = {
        "type": "Action",
        "pages": product_id,
        "language": "English",
        "publisher": "J. K. Rowlling"
    }
    if int(product_id) == 372:
        details_json["publisher"] = load_file_to_json('cards.json')
        return json.dumps(details_json), 200, {'Content-Type': 'application/json'}
    else:
        return json.dumps(details_json), 200, {'Content-Type': 'application/json'}


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("usage: %s port" % (sys.argv[0]))
        sys.exit(-1)

    port = int(sys.argv[1])
    print("started at port {}".format(port))
    app.run(host='0.0.0.0', port=port, debug=True, threaded=True)
