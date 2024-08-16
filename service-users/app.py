import os
import psycopg2
from flask import Flask, jsonify, request, make_response
from werkzeug.security import generate_password_hash, check_password_hash
import requests

app = Flask(__name__)

# Fetch the database connection details from environment variables
DATABASE_URL = os.getenv('DATABASE_URL')

def get_db_connection():
    conn = psycopg2.connect(DATABASE_URL)
    return conn

@app.route('/', methods=['GET'])
def home():
    return "Hello From user-service"

@app.route('/users', methods=['GET'])
def get_users():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT * FROM users;')
    users = cur.fetchall()
    cur.close()
    conn.close()

    return jsonify(users)


@app.route('/users', methods=['POST'])
def add_user():
    data = request.get_json()
    name = data.get('name')
    password = data.get('password')

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('INSERT INTO users (name, password) VALUES (%s, %s) RETURNING id;', (name, password))
    new_user_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"message": "User added", "user_id": new_user_id}), 201


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
