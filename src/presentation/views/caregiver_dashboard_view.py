import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY

class CaregiverDashboardView(ft.View):
    def __init__(self, page: ft.Page, user_name: str):
        super().__init__(route="/dashboard/caregiver", bgcolor=BACKGROUND_LIGHT)
        self.page = page
        self.user_name = user_name

        # --- AppBar ---
        self.appbar = ft.AppBar(
            title=ft.Text("Início", color=TEXT_LIGHT, weight=ft.FontWeight.BOLD),
            bgcolor=ft.Colors.WHITE,
            elevation=0,
            center_title=True,
            automatically_imply_leading=False,
            actions=[
                ft.IconButton(ft.Icons.NOTIFICATIONS_OUTLINED, icon_color=TEXT_LIGHT)
            ]
        )

        # --- Conteúdo das Abas ---
        self.tabs_content = [
            self._view_patients(), # Aba 0: Meus Pacientes
            self._view_alerts(),   # Aba 1: Alertas
            self._view_profile(),  # Aba 2: Perfil
        ]

        # --- Corpo ---
        self.body_container = ft.Container(
            content=self.tabs_content[0],
            expand=True,
            padding=20
        )

        # --- Navegação Inferior ---
        self.navigation_bar = ft.NavigationBar(
            selected_index=0,
            on_change=self.change_tab,
            bgcolor=ft.Colors.WHITE,
            indicator_color=ft.Colors.with_opacity(0.2, PRIMARY),
            destinations=[
                ft.NavigationBarDestination(icon=ft.Icons.PEOPLE_OUTLINE, selected_icon=ft.Icons.PEOPLE, label="Pacientes"),
                ft.NavigationBarDestination(icon=ft.Icons.WARNING_AMBER_OUTLINED, selected_icon=ft.Icons.WARNING_AMBER, label="Alertas"),
                ft.NavigationBarDestination(icon=ft.Icons.PERSON_OUTLINE, selected_icon=ft.Icons.PERSON, label="Perfil"),
            ]
        )

        self.controls = [self.body_container]

    def change_tab(self, e):
        index = e.control.selected_index
        self.body_container.content = self.tabs_content[index]
        
        titles = ["Meus Pacientes", "Alertas", "Meu Perfil"]
        self.appbar.title.value = titles[index]
        self.update()

    # --- ABA 1: PACIENTES ---
    def _view_patients(self):
        return ft.Column(
            [
                ft.Text(f"Olá, {self.user_name}", size=28, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                ft.Text("Quem você quer acompanhar?", size=16, color=TEXT_MUTED),
                ft.Container(height=20),
                
                # Lista de Pacientes
                self._patient_card("Maria Silva", "Mãe", 75),
                self._patient_card("João Pereira", "Pai", 30),
                self._patient_card("Ana Souza", "Tia", 90),
                
                ft.Container(height=20),
                
                # Botão de Adicionar
                ft.OutlinedButton(
                    "Adicionar Novo Paciente", 
                    icon=ft.Icons.ADD,
                    style=ft.ButtonStyle(
                        color=PRIMARY,
                        side=ft.BorderSide(1, PRIMARY),
                        shape=ft.RoundedRectangleBorder(radius=10),
                        padding=20
                    ),
                    width=float('inf'),
                    on_click=lambda e: print("Adicionar Paciente")
                )
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    # --- ABA 2: ALERTAS ---
    def _view_alerts(self):
        return ft.Column(
            [
                ft.Text("Atividades Recentes", size=20, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                ft.Container(height=10),
                self._alert_tile("Maria Silva não jogou hoje", ft.Icons.WARNING_AMBER, ft.Colors.ORANGE),
                self._alert_tile("João completou a meta!", ft.Icons.CHECK_CIRCLE, ft.Colors.GREEN),
                self._alert_tile("Relatório semanal disponível", ft.Icons.INSERT_CHART, PRIMARY),
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    # --- ABA 3: PERFIL ---
    def _view_profile(self):
        return ft.Column(
            [
                ft.Container(
                    alignment=ft.alignment.center,
                    content=ft.Column([
                        ft.CircleAvatar(radius=50, content=ft.Icon(ft.Icons.PERSON, size=50)),
                        ft.Text(self.user_name, size=22, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                        ft.Text("Cuidador Familiar", color=TEXT_MUTED),
                    ], horizontal_alignment=ft.CrossAxisAlignment.CENTER)
                ),
                ft.Container(height=30),
                ft.ListTile(leading=ft.Icon(ft.Icons.PERSON), title=ft.Text("Meus Dados"), trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT)),
                ft.ListTile(leading=ft.Icon(ft.Icons.SETTINGS), title=ft.Text("Configurações"), trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT)),
                ft.Divider(),
                ft.ListTile(
                    leading=ft.Icon(ft.Icons.LOGOUT, color=ft.Colors.RED), 
                    title=ft.Text("Sair", color=ft.Colors.RED), 
                    on_click=self.logout
                ),
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    # --- COMPONENTES VISUAIS ---
    def _patient_card(self, name, relation, progress):
        return ft.Container(
            padding=15,
            margin=ft.margin.only(bottom=10),
            bgcolor=ft.Colors.WHITE,
            border_radius=12,
            border=ft.border.all(1, ft.Colors.GREY_200),
            content=ft.Column([
                ft.Row([
                    ft.CircleAvatar(
                        content=ft.Text(name[0], weight=ft.FontWeight.BOLD), 
                        bgcolor=ft.Colors.BLUE_50, 
                        color=PRIMARY
                    ),
                    ft.Container(width=10),
                    ft.Column([
                        ft.Text(name, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT, size=16),
                        ft.Text(relation, color=TEXT_MUTED, size=12),
                    ], expand=True),
                    ft.Icon(ft.Icons.CHEVRON_RIGHT, color=TEXT_MUTED)
                ]),
                ft.Container(height=10),
                # Barra de Progresso
                ft.Row([
                    ft.ProgressBar(value=progress/100, color=PRIMARY, bgcolor=ft.Colors.GREY_100, expand=True),
                    ft.Container(width=10),
                    ft.Text(f"{progress}%", size=12, weight=ft.FontWeight.BOLD, color=PRIMARY)
                ])
            ]),
            ink=True,
            on_click=lambda e: print(f"Abrir detalhes de {name}")
        )

    def _alert_tile(self, text, icon, color):
        return ft.Container(
            margin=ft.margin.only(bottom=10),
            padding=10,
            bgcolor=ft.Colors.WHITE,
            border_radius=10,
            content=ft.Row([
                ft.Icon(icon, color=color),
                ft.Container(width=10),
                ft.Text(text, expand=True, color=TEXT_LIGHT)
            ])
        )

    def logout(self, e):
        self.page.client_storage.remove("supabase_token")
        self.page.client_storage.remove("user_role")
        self.page.go("/login")