#!/bin/bash

# Récupération du PORT via kubectl et jq
PORT=$(kubectl -n default get svc ${serviceName} -o json | jq .spec.ports[].nodePort)

# Donner les bonnes permissions au répertoire actuel
chmod 777 $(pwd)
echo $(id -u):$(id -g)

# Exécuter OWASP ZAP avec des règles personnalisées
docker run -it --rm ghcr.io/zaproxy/zaproxy:weekly /zap/bin/zap-bash -c "
    cd /zap/wrk
    zap-api-scan.py -t $applicationURL:$PORT/v3/api-docs -f openapi -c zap_rules -r zap_report.html
"

# Récupérer le code de sortie de l'exécution de Docker
exit_code=$?

# Créer un répertoire pour stocker le rapport ZAP
mkdir -p owasp-zap-report
mv zap_report.html owasp-zap-report

echo "Exit Code : $exit_code"

# Vérifier si le scan ZAP a trouvé des vulnérabilités
case $exit_code in
    0) echo "OWASP ZAP did not report any Risk";;
    1) echo "OWASP ZAP Report has either Low/Medium/High Risk. Please check the HTML Report";;
    *) echo "An unexpected error occurred during ZAP execution."; exit 1;;
esac

# Générer un fichier de configuration si nécessaire (ligne commentée)
# docker run -v $(pwd):/zap/wrk/:rw -t zaproxy/zap-stable zap-api-scan.py -t $applicationURL:$PORT/v3/api-docs -f openapi -g gen_file
