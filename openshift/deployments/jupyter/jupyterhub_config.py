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
os.environ['OAUTH2_TOKEN_URL'] = 'https://sso.192.168.99.100.nip.io/auth/realms/squonk/protocol/openid-connect/token'
os.environ['OAUTH2_AUTHORIZE_URL'] = 'https://sso.192.168.99.100.nip.io/auth/realms/squonk/protocol/openid-connect/auth'
os.environ['OAUTH2_USERDATA_URL'] = 'https://sso.192.168.99.100.nip.io/auth/realms/squonk/protocol/openid-connect/userinfo'
os.environ['OAUTH2_TLS_VERIFY'] = '0'
os.environ['OAUTH2_USERNAME_KEY'] = 'preferred_username'

from oauthenticator.generic import GenericOAuthenticator
c.JupyterHub.authenticator_class = GenericOAuthenticator
c.OAuthenticator.client_id = 'jupyterhub'
c.OAuthenticator.client_secret = 'ae2b5371-792d-4703-9a7c-4ec616d14415'
c.OAuthenticator.oauth_callback_url = 'https://jupyterhub-jupyter.192.168.99.100.nip.io/hub/oauth_callback'
c.OAuthenticator.tls_verify = False
c.OAuthenticator.login_service = 'Squonk SSO'
