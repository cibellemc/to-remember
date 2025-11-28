import os
import time
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

class AuthService:
    def __init__(self):
        self.url: str = os.environ.get("SUPABASE_URL")
        self.key: str = os.environ.get("SUPABASE_KEY")
        
        if not self.url or not self.key:
             raise Exception("Variáveis SUPABASE_URL ou SUPABASE_KEY ausentes no .env")

        self.supabase: Client = create_client(self.url, self.key)

    def login(self, email: str, password: str):
        try:
            response = self.supabase.auth.sign_in_with_password({
                "email": email, 
                "password": password
            })
            return response
        except Exception as e:
            raise Exception(f"Erro ao entrar: {str(e)}")

    # ATUALIZADO: Agora aceita photo_url e extra_data
    def register(self, name: str, email: str, password: str, role: str, photo_url: str = None, extra_data: dict = None):
        try:
            # Prepara os metadados base
            metadata = {
                "full_name": name,
                "role": role,
                "avatar_url": photo_url
            }
            
            # Se houver dados extras (CRM, especialidade, etc), adiciona ao dicionário
            if extra_data:
                metadata.update(extra_data)

            response = self.supabase.auth.sign_up({
                "email": email,
                "password": password,
                "options": {
                    "data": metadata # Envia tudo junto para o Supabase
                }
            })
            return response
        except Exception as e:
            raise Exception(f"Erro ao cadastrar: {str(e)}")

    def upload_avatar(self, file_path: str):
        """Faz upload da imagem para o bucket 'avatars' e retorna a URL pública."""
        try:
            # Gera um nome único para o arquivo
            filename = f"{int(time.time())}_{os.path.basename(file_path)}"
            
            with open(file_path, 'rb') as f:
                self.supabase.storage.from_("avatars").upload(
                    path=filename,
                    file=f,
                    file_options={"content-type": "image/png"} 
                )
            
            # Pega a URL pública para salvar no perfil
            public_url = self.supabase.storage.from_("avatars").get_public_url(filename)
            return public_url
        except Exception as e:
            print(f"Erro upload: {e}")
            return None

    def sign_out(self):
        self.supabase.auth.sign_out()