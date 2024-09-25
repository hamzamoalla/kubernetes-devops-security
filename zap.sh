#!/bin/bash

# Récupération du PORT via kubectl et jq
PORT=$(kubectl -n default get svc ${serviceName} -o json | jq .spec.ports[].nodePort)

# Donner les bonnes permissions au répertoire actuel
chmod 777 $(pwd)
echo $(id -u):$(id -g)

# Exécuter OWASP ZAP avec des règles personnalisées
docker run -v $(pwd):/zap/wrk/:rw -t zaproxy/zap-stable zap-api-scan.py -t $applicationURL:$PORT/v3/api-docs -f openapi -c zap_rules -r zap_report.html

# Récupérer le code de sortie de l'exécution de Docker
exit_code=$?

# Créer un répertoire pour stocker le rapport ZAP
mkdir -p owasp-zap-report
mv zap_report.html owasp-zap-report

echo "Exit Code : $exit_code"

# Vérifier si le scan ZAP a trouvé des vulnérabilités
if [[ ${exit_code} -ne 0 ]]; then
    echo "OWASP ZAP Report has either Low/Medium/High Risk. Please check the HTML Report"
    exit 1
else
    echo "OWASP ZAP did not report any Risk"
fi

# Générer un fichier de configuration si nécessaire (ligne commentée)
# docker run -v $(pwd):/zap/wrk/:rw -t zaproxy/zap-stable zap-api-scan.py -t $applicationURL:$PORT/v3/api-docs -f openapi -g gen_file
