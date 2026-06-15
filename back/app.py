from flask import Flask, jsonify
from flask_cors import CORS
import pymysql
import random
import dotenv
import os

app = Flask(__name__)
CORS(app)

dotenv.load_dotenv()

# Tes identifiants AWS RDS
DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

def get_connection():
    """Crée une connexion à l'instance RDS."""
    return pymysql.connect(
        host=DB_HOST, user=DB_USER, password=DB_PASSWORD, autocommit=True
    )

def init_db():
    """Initialise la base de données et la table sur RDS."""
    conn = get_connection()
    with conn.cursor() as cursor:
        # Création de la base de données interne si elle n'existe pas
        cursor.execute("CREATE DATABASE IF NOT EXISTS minecraft_db")
        cursor.execute("USE minecraft_db")
        
        # Création de la table avec la syntaxe MySQL
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS players (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(255) NOT NULL,
                blocks_broken INT NOT NULL
            )
        ''')
        
        # Injection des fausses données si la table est vide
        cursor.execute('SELECT COUNT(*) FROM players')
        if cursor.fetchone()[0] == 0:
            mock_players = ['Notch', 'Jeb_', 'Herobrine', 'Steve', 'Alex', 'CaptainSparklez', 'DanTDM']
            for player in mock_players:
                score = random.randint(1000, 50000)
                cursor.execute('INSERT INTO players (username, blocks_broken) VALUES (%s, %s)', (player, score))
    conn.close()

@app.route('/api/leaderboard', methods=['GET'])
def get_leaderboard():
    """Route REST pour Angular."""
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute("USE minecraft_db")
        cursor.execute('SELECT username, blocks_broken FROM players ORDER BY blocks_broken DESC LIMIT 10')
        rows = cursor.fetchall()
    conn.close()
    
    # Formatage JSON pour Angular
    leaderboard = [
        {"rank": index + 1, "username": row[0], "blocksBroken": row[1]} 
        for index, row in enumerate(rows)
    ]
    return jsonify(leaderboard)

if __name__ == '__main__':
    init_db()
    # Le host='0.0.0.0' est obligatoire pour que Flask écoute les requêtes de l'extérieur (le Load Balancer)
    app.run(host='0.0.0.0', port=5000)