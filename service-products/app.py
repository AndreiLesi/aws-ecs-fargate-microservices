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

def decimal_to_float(product):
    return {
        "id": product[0],
        "name": product[1],
        "price": float(product[2]) if isinstance(product[2], Decimal) else product[2]
    }

@app.route('/', methods=['GET'])
def home():
    return "Hello From product-service"

@app.route('/products', methods=['GET'])
def get_products():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT * FROM products;')
    products = cur.fetchall()
    cur.close()
    conn.close()
    
    products = [decimal_to_float(product) for product in products]

    return jsonify(products)

@app.route('/products', methods=['POST'])
def add_product():
    data = request.get_json()
    name = data.get('name')
    price = data.get('price')
    
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('INSERT INTO products (name, price) VALUES (%s, %s) RETURNING id;', (name, price))
    new_product_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()
    
    return jsonify({"message": "Product added", "product_id": new_product_id}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
