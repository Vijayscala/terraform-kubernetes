#cloud-config

write_files:
  - path: /etc/flannel/options.env
    owner: "root"
    content: |
      FLANNELD_IFACE=${ADVERTISE_IP}
      FLANNELD_ETCD_ENDPOINTS=${ETCD_ENDPOINTS}
  - path: /etc/kubernetes/cni/docker_opts_cni.env
    owner: "root"
    content: |
      DOCKER_OPT_BIP=""
      DOCKER_OPT_IPMASQ=""
  - path: /etc/kubernetes/cni/net.d/10-flannel.conf
    owner: "root"
    content: |
      {
          "name": "podnet",
          "type": "flannel",
          "delegate": {
              "isDefaultGateway": true
          }
      }
  - path: /etc/kubernetes/manifests/kube-apiserver.yaml
    owner: "root"
    content: |
      apiVersion: v1
      kind: Pod
      metadata:
        name: kube-apiserver
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: kube-apiserver
          image: quay.io/coreos/hyperkube:v1.5.4_coreos.0
          command:
          - /hyperkube
          - apiserver
          - --bind-address=0.0.0.0
          - --etcd-servers=${ETCD_ENDPOINTS}
          - --allow-privileged=true
          - --service-cluster-ip-range=${SERVICE_IP_RANGE}
          - --secure-port=443
          - --advertise-address=${ADVERTISE_IP}
          - --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota
          - --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem
          - --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
          - --client-ca-file=/etc/kubernetes/ssl/ca.pem
          - --service-account-key-file=/etc/kubernetes/ssl/apiserver-key.pem
          - --runtime-config=extensions/v1beta1/networkpolicies=true
          - --anonymous-auth=false
          livenessProbe:
            httpGet:
              host: 127.0.0.1
              port: 8080
              path: /healthz
            initialDelaySeconds: 15
            timeoutSeconds: 15
          ports:
          - containerPort: 443
            hostPort: 443
            name: https
          - containerPort: 8080
            hostPort: 8080
            name: local
          volumeMounts:
          - mountPath: /etc/kubernetes/ssl
            name: ssl-certs-kubernetes
            readOnly: true
          - mountPath: /etc/ssl/certs
            name: ssl-certs-host
            readOnly: true
        volumes:
        - hostPath:
            path: /etc/kubernetes/ssl
          name: ssl-certs-kubernetes
        - hostPath:
            path: /usr/share/ca-certificates
          name: ssl-certs-host
  - path: /etc/kubernetes/manifests/kube-proxy.yaml
    owner: "root"
    content: |
      apiVersion: v1
      kind: Pod
      metadata:
        name: kube-proxy
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: kube-proxy
          image: quay.io/coreos/hyperkube:v1.5.4_coreos.0
          command:
          - /hyperkube
          - proxy
          - --master=http://127.0.0.1:8080
          securityContext:
            privileged: true
          volumeMounts:
          - mountPath: /etc/ssl/certs
            name: ssl-certs-host
            readOnly: true
        volumes:
        - hostPath:
            path: /usr/share/ca-certificates
          name: ssl-certs-host
  - path: /etc/kubernetes/manifests/kube-controller-manager.yaml
    owner: "root"
    content: |
      apiVersion: v1
      kind: Pod
      metadata:
        name: kube-controller-manager
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: kube-controller-manager
          image: quay.io/coreos/hyperkube:v1.5.4_coreos.0
          command:
          - /hyperkube
          - controller-manager
          - --master=http://127.0.0.1:8080
          - --leader-elect=true
          - --service-account-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
          - --root-ca-file=/etc/kubernetes/ssl/ca.pem
          resources:
            requests:
              cpu: 200m
          livenessProbe:
            httpGet:
              host: 127.0.0.1
              path: /healthz
              port: 10252
            initialDelaySeconds: 15
            timeoutSeconds: 15
          volumeMounts:
          - mountPath: /etc/kubernetes/ssl
            name: ssl-certs-kubernetes
            readOnly: true
          - mountPath: /etc/ssl/certs
            name: ssl-certs-host
            readOnly: true
        volumes:
        - hostPath:
            path: /etc/kubernetes/ssl
          name: ssl-certs-kubernetes
        - hostPath:
            path: /usr/share/ca-certificates
          name: ssl-certs-host
  - path: /etc/kubernetes/manifests/kube-scheduler.yaml
    owner: "root"
    content: |
      apiVersion: v1
      kind: Pod
      metadata:
        name: kube-scheduler
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: kube-scheduler
          image: quay.io/coreos/hyperkube:v1.5.4_coreos.0
          command:
          - /hyperkube
          - scheduler
          - --master=http://127.0.0.1:8080
          - --leader-elect=true
          resources:
            requests:
              cpu: 100m
          livenessProbe:
            httpGet:
              host: 127.0.0.1
              path: /healthz
              port: 10251
            initialDelaySeconds: 15
            timeoutSeconds: 15


coreos:
  etcd2:
    discovery: "${discovery_token}"
    listen-client-urls: "http://0.0.0.0:2379"
    proxy: "on"
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
    - name: flanneld.service
      command: start
      enable: true
      drop-ins:
        - name: "40-ExecStartPre-symlink.conf"
          content: |
            [Service]
            ExecStartPre=/usr/bin/ln -sf /etc/flannel/options.env /run/flannel/options.env
        - name: 50-network-config.conf
          content: |
            [Service]
            ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config \
              '{ "Network": "${POD_NETWORK}", "Backend": {"Type": "host-gw"} }'
    - name: docker.service
      command: start
      drop-ins:
        - name: "40-flannel.conf"
          content: |
            [Unit]
            Requires=flanneld.service
            After=flanneld.service
            [Service]
            EnvironmentFile=/etc/kubernetes/cni/docker_opts_cni.env
    - name: kubelet.service
      command: start
      enable: true
      content: |
        [Service]
        Environment=KUBELET_IMAGE_TAG=${K8S_VER}
        Environment="RKT_RUN_ARGS=--uuid-file-save=/var/run/kubelet-pod.uuid \
          --volume var-log,kind=host,source=/var/log \
          --mount volume=var-log,target=/var/log \
          --volume dns,kind=host,source=/etc/resolv.conf \
          --mount volume=dns,target=/etc/resolv.conf"
        ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
        ExecStartPre=/usr/bin/mkdir -p /var/log/containers
        ExecStartPre=-/usr/bin/rkt rm --uuid-file=/var/run/kubelet-pod.uuid
        ExecStart=/usr/lib/coreos/kubelet-wrapper \
          --api-servers=http://127.0.0.1:8080 \
          --register-schedulable=false \
          --cni-conf-dir=/etc/kubernetes/cni/net.d \
          --container-runtime=docker \
          --allow-privileged=true \
          --pod-manifest-path=/etc/kubernetes/manifests \
          --hostname-override=${ADVERTISE_IP} \
          --cluster_dns=${DNS_SERVICE_IP} \
          --cluster_domain=cluster.local
        ExecStop=-/usr/bin/rkt stop --uuid-file=/var/run/kubelet-pod.uuid
        Restart=always
        RestartSec=10

        [Install]
        WantedBy=multi-user.target
