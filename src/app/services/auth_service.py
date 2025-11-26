import os
from supabase import create_client, Client
from dotenv import load_dotenv
load_dotenv()
class AuthService:
    def __init__(self):
        self.url: str = os.environ.get("SUPABASE_URL")
        self.key: str = os.environ.get("SUPABASE_KEY")
        
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

    # def register(self, name: str, email: str, password: str, role: str):
    #     try:
            
    #         response = self.supabase.auth.sign_up({
    #             "email": email,
    #             "password": password,
    #             "options": {
    #                 "data": {
    #                     "full_name": name,
    #                     "role": role # Salva se é 'patient' ou 'caregiver'
    #                 }
    #             }
    #         })
    #         return response
    #     except Exception as e:
    #         raise Exception(f"Erro ao cadastrar: {str(e)}")

    def sign_out(self):
        self.supabase.auth.sign_out()