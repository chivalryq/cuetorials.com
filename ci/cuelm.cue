package ci

import (
	"github.com/hofstadter-io/cuelm/schema"
)

Install: schema.#List & {
	items: [
		#Cuetorials.Ingress,
		#Cuetorials.Service,
		#Cuetorials.Deployment,
	]
}

Update: schema.#List & {
	items: [
		#Cuetorials.Deployment,
	]
}

#Cuetorials: {
	_Values: {
		name: "cuetorials"
		namespace: "websites"

		registry: "us.gcr.io/hof-io--develop"
		image: "cuetorials.com"
		version: string | *"manual" @tag(version)

		domain: string | *"cuetorials.com" @tag(domain)
		port: 80

		#metadata: {
			name: _Values.name
			namespace: _Values.namespace
			labels: {
				app: _Values.name
			}
			...
		}
	}

	Ingress: schema.#Ingress & {
		metadata: _Values.#metadata & {
			annotations: {
				"kubernetes.io/tls-acme": "true"
				"kubernetes.io/ingress.class": "nginx"
				"nginx.ingress.kubernetes.io/force-ssl-redirect": "true"
				"cert-manager.io/cluster-issuer": "letsencrypt-prod"
			}
		} // END Ingress.metadata

		spec: {
			tls: [{
				hosts: [_Values.domain]
				secretName: "\(_Values.name)-tls"
			}]

			rules: [{
				host: _Values.domain
				http: paths: [{
					backend: {
						service: {
							name: Service.metadata.name
							port: "number": Service.spec.ports[0].port
						}
					}
				}]
			}]

		} // END Ingress.spec
	} // END Ingress

	Service: schema.#Service & {
		metadata: _Values.#metadata
		spec: {
			selector: _Values.#metadata.labels
			type: "NodePort"
			ports: [{
				port: _Values.port
				targetPort: _Values.port
			}]
		}
	}

	Deployment: schema.#Deployment & {
		metadata: _Values.#metadata
		spec: {
			selector: matchLabels: _Values.#metadata.labels

			template: {
				metadata: labels: _Values.#metadata.labels
				spec: {
					containers: [{
						name: "website"
						image: "\(_Values.registry)/\(_Values.image):\(_Values.version)"
						imagePullPolicy: "Always"
						ports: [{
							containerPort: _Values.port
							protocol: "TCP"
						}]
						readinessProbe: {
							httpGet: port: _Values.port
							initialDelaySeconds: 6
							failureThreshold: 3
							periodSeconds: 10
						}
						livenessProbe: {
							httpGet: port: _Values.port
							initialDelaySeconds: 6
							failureThreshold: 3
							periodSeconds: 10
						}
					}]
				}
			}
		}
	}

}


