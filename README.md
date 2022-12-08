# This repo is made to build a documize docker image

Command to build the image : 

docker build -t xhelliom/documize:latest .

docker push xhelliom/documize:latest

# documize
---

A non-official documize docker container forked from : https://registry.hub.docker.com/u/ansrivas/documize-ce/ or https://github.com/ansrivas/documize/


---

# Environement variables to use (with default value):

ENV DOCUMIZESALT="somethingsupersecret" \
DOCUMIZEDB="host=documize-postgres-s port=5432 sslmode=disable user=testuser password=testpassword123 dbname=testdb" \
POSTGRES_DB="testdb" \
POSTGRES_USER="testuser" \
POSTGRES_PASSWORD="testpassword123" \
DOCUMIZEDB="host=documize-postgres-s port=5432 sslmode=disable user=testuser password=testpassword123 dbname=testdb" \
DOCUMIZEDBTYPE="postgresql" \
DOCUMIZESALT="somethingsupersecret" \
DOCUMIZEPORT="5001"


# Example:


## Docker:

To use the builded docker image, you can use the file include in the [_examples](https://github.com/Xhelliom/documize/blob/master/_example/docker-compose.yml) directory.

- Change the username-password details in `env.list` file
- Make persistent volume for the `postgres` container using this command:

  `docker volume create --name=pgdata`

- Now run

 `docker-compose -f _examples/docker-compose.yml`

## Kubernete YAML file:

#Documize deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: documize-ce-server-s
  name: documize-ce-server-s
spec:
  replicas: 1
  selector:
    matchLabels:
      name: documize-ce-server-s
  template:
    metadata:
      labels:
        name: documize-ce-server-s
    spec:
      containers:
        - image: xhelliom/documize:latest
          name: documize-ce-server-c
          args:
            - /usr/local/bin/documize
          env:
            - name: DOCUMIZEDB
              valueFrom:
                configMapKeyRef:
                  key: DOCUMIZEDB
                  name: env-list
            - name: DOCUMIZEDBTYPE
              valueFrom:
                configMapKeyRef:
                  key: DOCUMIZEDBTYPE
                  name: env-list
            - name: DOCUMIZEPORT
              valueFrom:
                configMapKeyRef:
                  key: DOCUMIZEPORT
                  name: env-list
            - name: DOCUMIZESALT
              valueFrom:
                configMapKeyRef:
                  key: DOCUMIZESALT
                  name: env-list
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  key: POSTGRES_DB
                  name: env-list
            - name: POSTGRES_PASSWORD
              valueFrom:
                configMapKeyRef:
                  key: POSTGRES_PASSWORD
                  name: env-list
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  key: POSTGRES_USER
                  name: env-list
          ports:
            - containerPort: 5001
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "1024Mi"
              cpu: "500m"
        - image: postgres:11-alpine
          name: documize-postgres-c
          env:
            - name: DOCUMIZEDB
              valueFrom:
                configMapKeyRef:
                  key: DOCUMIZEDB
                  name: env-list
            - name: DOCUMIZEDBTYPE
              valueFrom:
                configMapKeyRef:
                  key: DOCUMIZEDBTYPE
                  name: env-list
            - name: DOCUMIZEPORT
              valueFrom:
                configMapKeyRef:
                  key: DOCUMIZEPORT
                  name: env-list
            - name: DOCUMIZESALT
              valueFrom:
                configMapKeyRef:
                  key: DOCUMIZESALT
                  name: env-list
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  key: POSTGRES_DB
                  name: env-list
            - name: POSTGRES_PASSWORD
              valueFrom:
                configMapKeyRef:
                  key: POSTGRES_PASSWORD
                  name: env-list
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  key: POSTGRES_USER
                  name: env-list
          ports:
            - containerPort: 5432
          resources:             
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "1024Mi"
              cpu: "500m"
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: pgdata
      restartPolicy: Always
      volumes:
        - name: pgdata
          persistentVolumeClaim:
            claimName: pgdata

--- #Documize service
apiVersion: v1
kind: Service
metadata:
  labels:
    name: documize-ce-server-s
  name: documize-ce-server-s
spec:
  ports:
    - name: "5001"
      port: 5001
      targetPort: 5001
  selector:
    name: documize-ce-server-s

--- #congifmap
apiVersion: v1
data:
  DOCUMIZEDB: host=localhost port=5432 sslmode=disable user=documize password=password dbname=documizedb
  DOCUMIZEDBTYPE: postgresql
  DOCUMIZEPORT: "5001"
  DOCUMIZESALT: salt
  POSTGRES_DB: documizedb
  POSTGRES_PASSWORD: password
  POSTGRES_USER: documize
kind: ConfigMap
metadata:
  labels:
    name: documize-ce-server-s-env-list
  name: env-list
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: documize-certificate
spec:
  commonName: documize.example.com
  secretName: documize-cert-secret
  dnsNames:
    - documize.example.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: documize-ingress-route
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`documize.example.com`)
      kind: Rule
      services:
        - name: documize-ce-server-s
          port: 5001
  tls:
    secretName: documize-cert-secret
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: documize-ingress-route-redirect
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`documize.example.com`)
      kind: Rule
      services:
        - name: documize-ce-server-s
          port: 5001
      middlewares:
        - name: https-redirectscheme
          namespace: default


