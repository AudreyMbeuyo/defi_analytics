from pathlib import Path
import pandas as pd

# Chemin vers le dossier de données
data_dir = Path(__file__).resolve().parent.parent / "data"

# On parcourt chaque fichier du dossier par ordre alphabétique
for file_path in sorted(data_dir.iterdir()):
    size_mb = file_path.stat().st_size / (1024 * 1024)

    # On lit le fichier selon son extension (.csv ou .parquet)
    if file_path.suffix == ".csv":
        df = pd.read_csv(file_path)
    elif file_path.suffix == ".parquet":
        df = pd.read_parquet(file_path)
    else:
        continue

    # On affiche le résumé : nom, taille, nb lignes, colonnes et 1 exemple
    print(f"=== {file_path.name} ({size_mb:.2f} Mo) ===")
    print(f"Lignes : {len(df)} | Colonnes ({len(df.columns)}) : {list(df.columns)}")
    print("Aperçu :", df.head(1).to_dict(orient="records"))
    print()

