import os
import psycopg2
from flask import Flask, jsonify, request
from decimal import Decimal

app = Flask(__name__)

# Fetch the database connection details from environment variables
DATABASE_URL = os.getenv('DATABASE_URL')

def get_db_connection():
    conn = psycopg2.connect(DATABASE_URL)
    return conn

@app.route('/', methods=['GET'])
def home():
    return "Hello From order-service"


@app.route('/orders', methods=['GET'])
def get_orders():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT * FROM orders;')
    orders = cur.fetchall()
    cur.close()
    conn.close()

    return jsonify(orders)

@app.route('/orders', methods=['POST'])
def add_order():
    data = request.get_json()
    user_id = data.get('user_id')
    product_id = data.get('product_id')
    quantity = data.get('quantity')

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('INSERT INTO orders (user_id, product_id, quantity) VALUES (%s, %s, %s) RETURNING id;', (user_id, product_id, quantity))
    new_order_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"message": "Order placed", "order_id": new_order_id}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
