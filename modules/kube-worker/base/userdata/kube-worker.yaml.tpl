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
          image: quay.io/coreos/hyperkube:v1.6.1_coreos.0
          command:
          - /hyperkube
          - proxy
          - --master=${MASTER_HOST}
          - --kubeconfig=/etc/kubernetes/worker-kubeconfig.yaml
          securityContext:
            privileged: true
          volumeMounts:
          - mountPath: /etc/ssl/certs
            name: "ssl-certs"
          - mountPath: /etc/kubernetes/worker-kubeconfig.yaml
            name: "kubeconfig"
            readOnly: true
          - mountPath: /etc/kubernetes/ssl
            name: "etc-kube-ssl"
            readOnly: true
        volumes:
        - name: "ssl-certs"
          hostPath:
            path: "/usr/share/ca-certificates"
        - name: "kubeconfig"
          hostPath:
            path: "/etc/kubernetes/worker-kubeconfig.yaml"
        - name: "etc-kube-ssl"
          hostPath:
            path: "/etc/kubernetes/ssl"
  - path: /etc/kubernetes/worker-kubeconfig.yaml
    owner: "root"
    content: |
      apiVersion: v1
      kind: Config
      clusters:
      - name: local
        cluster:
          certificate-authority: /etc/kubernetes/ssl/ca.pem
      users:
      - name: kubelet
        user:
          client-certificate: /etc/kubernetes/ssl/worker.pem
          client-key: /etc/kubernetes/ssl/worker-key.pem
      contexts:
      - context:
          cluster: local
          user: kubelet
        name: kubelet-context
      current-context: kubelet-context


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
          --volume dns,kind=host,source=/etc/resolv.conf \
          --mount volume=dns,target=/etc/resolv.conf \
          --volume var-log,kind=host,source=/var/log \
          --mount volume=var-log,target=/var/log"
        ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
        ExecStartPre=/usr/bin/mkdir -p /var/log/containers
        ExecStartPre=-/usr/bin/rkt rm --uuid-file=/var/run/kubelet-pod.uuid
        ExecStart=/usr/lib/coreos/kubelet-wrapper \
          --api-servers=https://${MASTER_HOST} \
          --cni-conf-dir=/etc/kubernetes/cni/net.d \
          --container-runtime=docker \
          --register-node=true \
          --allow-privileged=true \
          --pod-manifest-path=/etc/kubernetes/manifests \
          --hostname-override=${ADVERTISE_IP} \
          --cluster_dns=${DNS_SERVICE_IP} \
          --cluster_domain=cluster.local \
          --kubeconfig=/etc/kubernetes/worker-kubeconfig.yaml \
          --tls-cert-file=/etc/kubernetes/ssl/worker.pem \
          --tls-private-key-file=/etc/kubernetes/ssl/worker-key.pem
        ExecStop=-/usr/bin/rkt stop --uuid-file=/var/run/kubelet-pod.uuid
        Restart=always
        RestartSec=10

        [Install]
        WantedBy=multi-user.target