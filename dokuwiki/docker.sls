{% import_yaml "dokuwiki/defaults.yaml" as defaults %}

{% set images = [] %}
{% for docker_name in salt['pillar.get']('dokuwiki:dockers', {}) %}
{% set docker = salt['pillar.get']('dokuwiki:dockers:' ~ docker_name,
                                   default=defaults.docker, merge=True) %}
{% set docker_image = docker.image if ':' in docker.image else docker.image ~ ':latest' %}
{% do images.append(docker_image) if docker_image not in images %}

dokuwiki-docker_{{ docker_name }}_running:
  dockerng.running:
    - name: {{ docker_name }}
    - image: {{ docker.image }}
    - binds:
      - {{ docker.data_dir }}:{{ docker.docker_data_dir }}
    - ports:
      - {{ docker.docker_http_port }}
    - require:
      - cmd: dokuwiki-docker-image_{{ docker_image }}

dockuwiki-docker_{{ docker_name }}_volume:
  file.directory:
    - name: {{ docker.data_dir }}
    - makedirs: True
#  module.run:
#    - name: file.set_selinux_context
#    - path: {{ docker.data_dir }}
#    - type: svirt_sandbox_file_t
#    - require:
#      - file: {{ docker.data_dir }}
    - require_in:
      - dockerng: {{ docker_name }}
{% endfor %}

{% for image in images %}
dokuwiki-docker-image_{{ image }}:
  cmd.run:
    - name: docker pull {{ image }}
    - unless: '[ $(docker images -q {{ image }}) ]'
{% endfor %}
