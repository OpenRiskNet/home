c.JupyterHub.spawner_class = 'kubespawner.KubeSpawner'

c.KubeSpawner.start_timeout = 600
c.KubeSpawner.http_timeout = 120

c.KubeSpawner.environment = dict(JUPYTER_ENABLE_LAB='true')


c.KubeSpawner.profile_list = [
    {
        'display_name': 'Minimal Notebook (CentOS 7 / Python 3.6)',
        'default': True,
        'kubespawner_override': {
            'image_spec': 's2i-minimal-notebook:3.6'
        }
    },{
        'display_name': 'SciPy Notebook (CentOS 7 / Python 3.6)',
        'kubespawner_override': {
            'image_spec': 's2i-scipy-notebook:3.6'
        }
    },{
        'display_name': 'Tensorflow Notebook (CentOS 7 / Python 3.6)',
        'kubespawner_override': {
            'image_spec': 's2i-tensorflow-notebook:3.6'
        }
    },{
        'display_name': 'RDKit (Ubuntu 18.04 / Python 3.7)',
        'kubespawner_override': {
            'image_spec': 'simple-rdkit:latest',
            'supplemental_gids': [100,65534],
            'volume_mounts': [
                {
                    'name': 'data',
                    'mountPath': '/home/jovyan'
                }
            ]
        }
    },{
        'display_name': 'SPARQL Notebook (CentOS 7 / Python 3.6 / SPARQL)',
        'kubespawner_override': {
            'image_spec': 's2i-sparql-notebook:latest'
        }
    },{
        'display_name': 'Nextflow (Ubuntu 18.04 / Java 10)',
        'kubespawner_override': {
            'image_spec': 'nextflow:latest',
            'supplemental_gids': [100,65534],
            'volume_mounts': [
                {
                    'name': 'data',
                    'mountPath': '/home/jovyan'
                }
            ]
        }
    },{
        'display_name': 'Datascience (Python, R and Julia) - big image, longer load times',
        'kubespawner_override': {
            'image_spec': 'docker.io/jupyter/datascience-notebook:7a3e968dd212',
            'mem_guarantee': '1G',
            'mem_limit': '3G',
            'supplemental_gids': [100,65534],
            'volume_mounts': [
                {
                    'name': 'data',
                    'mountPath': '/home/jovyan'
                }
            ]
        }
    }
]

# authentication

import os
os.environ['OAUTH2_TOKEN_URL'] = 'https://sso.prod.openrisknet.org/auth/realms/openrisknet/protocol/openid-connect/token'  
os.environ['OAUTH2_AUTHORIZE_URL'] = 'https://sso.prod.openrisknet.org/auth/realms/openrisknet/protocol/openid-connect/auth'  
os.environ['OAUTH2_USERDATA_URL'] = 'https://sso.prod.openrisknet.org/auth/realms/openrisknet/protocol/openid-connect/userinfo'  
os.environ['OAUTH2_TLS_VERIFY'] = '1'
os.environ['OAUTH2_USERNAME_KEY'] = 'preferred_username'

from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator
c.OAuthenticator.client_id = 'jupyterhub'
c.OAuthenticator.client_secret = '<clinet-secret>'
c.OAuthenticator.oauth_callback_url = '<callback-url>'  
c.OAuthenticator.tls_verify = True
c.OAuthenticator.login_service = 'OpenRiskNet SSO'


# storage
c.KubeSpawner.user_storage_pvc_ensure = True
c.KubeSpawner.pvc_name_template = 'jupyterhub-{username}'
c.KubeSpawner.user_storage_capacity = '1Gi'
c.KubeSpawner.supplemental_gids = [ 65534 ]
c.KubeSpawner.storage_class = ''
c.KubeSpawner.storage_selector = { 'matchLabels': {'purpose': 'jupyter'}}
c.KubeSpawner.volumes = [
    {
        'name': 'data',
        'persistentVolumeClaim': {
            'claimName': c.KubeSpawner.pvc_name_template
        }
    }
]
c.KubeSpawner.volume_mounts = [
    {
        'name': 'data',
        'mountPath': '/opt/app-root/src'
    }
]
c.JupyterHub.services = [ {
    'name': 'cull-idle',
    'admin': True,
    'command': ['cull-idle-servers', '--timeout=3600'],
} ]
