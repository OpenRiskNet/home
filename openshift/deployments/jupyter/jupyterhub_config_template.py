c.JupyterHub.spawner_class = 'kubespawner.KubeSpawner'

c.KubeSpawner.start_timeout = 180
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
    }
]

# authentication

import os
os.environ['OAUTH2_TOKEN_URL'] = 'https://<keycloak-server>/auth/realms/<realm-name>/protocol/openid-connect/token'
os.environ['OAUTH2_AUTHORIZE_URL'] = 'https://<keycloak-server>/auth/realms/<realm-name>/protocol/openid-connect/auth'
os.environ['OAUTH2_USERDATA_URL'] = 'https://<keycloak-server>/auth/realms/<realm-name>/protocol/openid-connect/userinfo'
os.environ['OAUTH2_TLS_VERIFY'] = '0'
os.environ['OAUTH2_USERNAME_KEY'] = 'preferred_username'

from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator
c.OAuthenticator.client_id = 'jupyterhub'
c.OAuthenticator.client_secret = '<client-secret>'
c.OAuthenticator.oauth_callback_url = 'https://<juputerhub-route>/hub/oauth_callback'
c.OAuthenticator.tls_verify = False
c.OAuthenticator.login_service = 'OpenRiskNet SSO'


# storage
c.KubeSpawner.user_storage_pvc_ensure = True
c.KubeSpawner.pvc_name_template = 'jupyterhub-nb-{username}'
c.KubeSpawner.user_storage_capacity = '1Gi'
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