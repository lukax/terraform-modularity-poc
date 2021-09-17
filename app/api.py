from flask import Flask
from flask import jsonify
from flask import request
from applicationinsights.flask.ext import AppInsights
import os


app_name = 'comentarios'
app = Flask(app_name)
app.debug = True

app.config['APPINSIGHTS_INSTRUMENTATIONKEY'] = os.environ.get('APPINSIGHTS_INSTRUMENTATIONKEY')
appinsights = AppInsights(app)

comments = {}

@app.route('/api/comment/new', methods=['POST'])
def api_comment_new():
    request_data = request.get_json()

    email = request_data['email']
    comment = request_data['comment']
    content_id = '{}'.format(request_data['content_id'])

    new_comment = {
            'email': email,
            'comment': comment,
            }

    if content_id in comments:
        comments[content_id].append(new_comment)
    else:
        comments[content_id] = [new_comment]

    message = 'comment created and associated with content_id {}'.format(content_id)
    response = {
            'status': 'SUCCESS',
            'message': message,
            }
    return jsonify(response)


@app.route('/api/comment/list/<content_id>')
def api_comment_list(content_id):
    content_id = '{}'.format(content_id)

    if content_id in comments:
        return jsonify(comments[content_id])
    else:
        message = 'content_id {} not found'.format(content_id)
        response = {
                'status': 'NOT-FOUND',
                'message': message,
                }
        return jsonify(response), 404


@app.route('/health')
def health():

    response = {
            'message': 'Healthy',
            }
    return jsonify(response), 200


# force flushing application insights handler after each request
@app.after_request
def after_request(response):
    appinsights.flush()
    return response