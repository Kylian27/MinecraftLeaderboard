from flask import Flask, jsonify
from flask_cors import CORS
import sqlite3
import random

app = Flask(__name__)
# Autorise les requêtes cross-origin pour Angular
CORS(app)

DB_FILE = 'minecraft.db'

def init_db():
    """Initialise la base de données avec des fausses données si elle est vide."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Création de la table (schéma très proche de ce que tu auras sur RDS)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            blocks_broken INTEGER NOT NULL
        )
    ''')
    
    # Vérifie si la table est vide
    cursor.execute('SELECT COUNT(*) FROM players')
    if cursor.fetchone()[0] == 0:
        print("Génération des données de test...")
        mock_players = ['Notch', 'Jeb_', 'Herobrine', 'Steve', 'Alex', 'CaptainSparklez', 'DanTDM', 'Munchjin', 'BasilicEsp7', 'Pipepsycho']
        for player in mock_players:
            score = random.randint(1000, 50000)
            cursor.execute('INSERT INTO players (username, blocks_broken) VALUES (?, ?)', (player, score))
        conn.commit()
        
    conn.close()

@app.route('/api/leaderboard', methods=['GET'])
def get_leaderboard():
    """Route REST pour récupérer le top 10 des joueurs."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    
    # Récupère les joueurs triés par blocs cassés
    cursor.execute('SELECT username, blocks_broken FROM players ORDER BY blocks_broken DESC LIMIT 10')
    rows = cursor.fetchall()
    conn.close()
    
    # Formatage en JSON pour Angular
    leaderboard = [
        {"rank": index + 1, "username": row[0], "blocksBroken": row[1]} 
        for index, row in enumerate(rows)
    ]
    
    return jsonify(leaderboard)

if __name__ == '__main__':
    init_db()
    # Lancement du serveur sur le port 5000
    app.run(debug=True, port=5000)