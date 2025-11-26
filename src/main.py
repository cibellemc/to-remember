import flet as ft

# 1. Importe todas as suas "telas" (Views)
from app.services.auth_service import AuthService
from presentation.views.welcome_view import WelcomeView
from presentation.views.select_role_view import SelectRoleView
from presentation.views.login_view import LoginView
from presentation.views.register_view import RegisterView
from presentation.views.dashboard_view import DashboardView
from common.colors import PRIMARY, BACKGROUND_LIGHT, TEXT_LIGHT, BACKGROUND_DARK

def main(page: ft.Page):
    page.fonts = {
        "Lexend": "https://fonts.googleapis.com/css2?family=Lexend:wght@400;500;700;900&display=swap"
    }
    page.title = "To Remember"
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
    page.window_width = 400
    page.window_height = 850
    page.window_resizable = True

    page.theme_mode = ft.ThemeMode.LIGHT 
    page.theme = ft.Theme(
        color_scheme_seed=PRIMARY, 
        font_family="Lexend",
        color_scheme=ft.ColorScheme(
            primary=PRIMARY,
            background=BACKGROUND_LIGHT,
            on_background=TEXT_LIGHT, 
            on_surface_variant=ft.Colors.GREY_200, 
        )
    )
    
    auth_service = AuthService()
    
    def route_change(route):
        page.views.clear()

        # 1. Rota: / (Tela de Boas-Vindas)
        page.views.append(
            WelcomeView(page)
        )

        # 2. Rota: /select-role (Seleção de Perfil)
        if page.route == "/select-role":
            page.views.append(
                SelectRoleView(page)
            )

        # 3. Rota: /login/[perfil] (Tela de Login)
        elif page.route.startswith("/login/"):
            # Extrai o perfil (paciente ou cuidador) da URL
            role = page.route.split("/")[-1]
            page.views.append(SelectRoleView(page)) # Adiciona a tela anterior
            page.views.append(
                LoginView(page, role, auth_service) # Passa o perfil para a View
            )

        # 4. Rota: /register/[perfil] (Tela de Cadastro)
        elif page.route.startswith("/register/"):
            role = page.route.split("/")[-1]
            page.views.append(SelectRoleView(page)) # Adiciona a tela base
            page.views.append(LoginView(page, role, auth_service=None)) # Adiciona o login
            page.views.append(
                RegisterView(page, role, auth_service=None) # Adiciona o cadastro no topo
            )

        # 5. Rota: /dashboard/[perfil] (Tela Inicial - Pós-Login)
        elif page.route.startswith("/dashboard/"):
            role = page.route.split("/")[-1]
            page.views.append(
                DashboardView(page, role)
            )

        page.update()

    def view_pop(view):
        if page.views:
            top_view = page.views[-1]
            page.go(top_view.route)
        else:
            page.go("/") 

    page.on_route_change = route_change
    page.on_view_pop = view_pop
    
    page.go("/") 

ft.app(target=main)
