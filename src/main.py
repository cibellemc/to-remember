import flet as ft

# 1. Importe todas as suas Views
from presentation.views.register_specifics_view import RegisterSpecificsView
from presentation.views.welcome_view import WelcomeView
from presentation.views.select_role_view import SelectRoleView
from presentation.views.login_view import LoginView
from presentation.views.register_view import RegisterView
# Importe as NOVAS Views separadas
from presentation.views.patient_dashboard_view import PatientDashboardView
from presentation.views.caregiver_dashboard_view import CaregiverDashboardView

# 2. Importe o AuthService e as Cores
from app.services.auth_service import AuthService
from common.colors import PRIMARY, BACKGROUND_LIGHT, TEXT_LIGHT

def main(page: ft.Page):
    # --- Configurações da Página ---
    page.fonts = {
        "Lexend": "https://fonts.googleapis.com/css2?family=Lexend:wght@400;500;700;900&display=swap"
    }
    page.title = "To Remember"
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
    page.window_width = 400
    page.window_height = 850
    page.window_resizable = True

    # --- Tema ---
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

    # --- 3. Inicializa o AuthService ---
    auth_service = AuthService()

    def route_change(route):
        page.views.clear()

        # Rota 1: Login Genérico
        if page.route == "/" or page.route == "/login":
             page.views.append(LoginView(page, auth_service))

        # Rota 2: Welcome
        elif page.route == "/welcome":
             page.views.append(WelcomeView(page))

        # Rota 3: Seleção de Perfil
        elif page.route == "/select-role":
            page.views.append(SelectRoleView(page))

        # Rota 4: Cadastro Passo 2
        elif page.route.startswith("/register/") and "step3" not in page.route:
            role = page.route.split("/")[-1]
            if "step2" in role: role = page.route.split("/")[-1] 
            page.views.append(RegisterView(page, role, auth_service))

        # Rota 5: Cadastro Passo 3
        elif page.route.startswith("/register/step3/"):
            role = page.route.split("/")[-1]
            basic_data = page.session.get("temp_register_data")
            if basic_data:
                page.views.append(RegisterSpecificsView(page, role, basic_data, auth_service))
            else:
                page.go("/login")

        # Rota 6: Dashboard (SEPARADA)
        elif page.route.startswith("/dashboard/"):
            role = page.route.split("/")[-1]
            user_name = page.session.get("user_name") or ""
            
            # Decide qual View mostrar
            if role == "patient":
                page.views.append(PatientDashboardView(page, user_name))
            else:
                page.views.append(CaregiverDashboardView(page, user_name))

        page.update()

    def view_pop(view):
        page.views.pop()
        top_view = page.views[-1]
        page.go(top_view.route)

    page.on_route_change = route_change
    page.on_view_pop = view_pop
    
    # --- Lógica de Inicialização ---
    if page.client_storage.contains_key("welcome_seen"):
        page.go("/login")
    else:
        page.go("/welcome")

ft.app(target=main)