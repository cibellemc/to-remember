import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY

class PatientDashboardView(ft.View):
    def __init__(self, page: ft.Page, user_name: str):
        super().__init__(route="/dashboard/patient", bgcolor=BACKGROUND_LIGHT)
        self.page = page
        self.user_name = user_name

        self.appbar = ft.AppBar(
            title=ft.Text("Jogos", color=TEXT_LIGHT, weight=ft.FontWeight.BOLD),
            bgcolor=ft.Colors.WHITE,
            elevation=0,
            center_title=True,
            automatically_imply_leading=False,
        )

        self.tabs_content = [
            self._view_games(),
            self._view_progress(),
            self._view_profile(),
        ]

        self.body_container = ft.Container(content=self.tabs_content[0], expand=True, padding=20)

        self.navigation_bar = ft.NavigationBar(
            selected_index=0,
            on_change=self.change_tab,
            bgcolor=ft.Colors.WHITE,
            indicator_color=ft.Colors.with_opacity(0.2, PRIMARY),
            destinations=[
                ft.NavigationBarDestination(icon=ft.Icons.GAMEPAD_OUTLINED, selected_icon=ft.Icons.GAMEPAD, label="Jogos"),
                ft.NavigationBarDestination(icon=ft.Icons.BAR_CHART_OUTLINED, selected_icon=ft.Icons.BAR_CHART, label="Progresso"),
                ft.NavigationBarDestination(icon=ft.Icons.PERSON_OUTLINE, selected_icon=ft.Icons.PERSON, label="Perfil"),
            ]
        )
        self.controls = [self.body_container]

    def change_tab(self, e):
        index = e.control.selected_index
        self.body_container.content = self.tabs_content[index]
        titles = ["Jogos", "Meu Progresso", "Meu Perfil"]
        self.appbar.title.value = titles[index]
        self.update()

    def _view_games(self):
        return ft.Column(
            [
                ft.Text(f"Olá, {self.user_name}!", size=28, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                ft.Text("Vamos exercitar a mente hoje?", size=16, color=TEXT_MUTED),
                ft.Container(height=20),
                self._game_card("Memória", ft.Icons.MEMORY, "Encontre os pares", ft.Colors.BLUE),
                self._game_card("Lógica", ft.Icons.LIGHTBULB, "Resolva os desafios", ft.Colors.ORANGE),
                self._game_card("Foco", ft.Icons.CENTER_FOCUS_STRONG, "Atenção plena", ft.Colors.PURPLE),
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    def _view_progress(self):
        return ft.Column([
            ft.Container(
                height=200, 
                bgcolor=ft.Colors.WHITE, 
                border_radius=16,
                content=ft.Column([
                    ft.Text("Pontos Totais", color=TEXT_MUTED),
                    ft.Text("1.250", size=40, weight=ft.FontWeight.BOLD, color=PRIMARY),
                    ft.Text("+100 hoje", color=ft.Colors.GREEN)
                ], alignment=ft.MainAxisAlignment.CENTER, horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                alignment=ft.alignment.center
            )
        ])

    def _view_profile(self):
        return ft.Column([
            ft.Container(
                alignment=ft.alignment.center,
                content=ft.Column([
                    ft.CircleAvatar(radius=50, content=ft.Icon(ft.Icons.PERSON, size=50)),
                    ft.Text(self.user_name, size=22, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER)
            ),
            ft.Container(height=30),
            ft.ListTile(leading=ft.Icon(ft.Icons.LOGOUT, color=ft.Colors.RED), title=ft.Text("Sair", color=ft.Colors.RED), on_click=self.logout),
        ])

    def _game_card(self, title, icon, subtitle, color):
        return ft.Container(
            padding=20,
            margin=ft.margin.only(bottom=15),
            bgcolor=ft.Colors.WHITE,
            border_radius=16,
            content=ft.Row([
                ft.Container(content=ft.Icon(icon, color=color, size=30), bgcolor=ft.Colors.with_opacity(0.1, color), padding=12, border_radius=12),
                ft.Container(width=15),
                ft.Column([
                    ft.Text(title, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT, size=18),
                    ft.Text(subtitle, color=TEXT_MUTED, size=13),
                ], expand=True),
                ft.Icon(ft.Icons.PLAY_CIRCLE_FILL, color=PRIMARY, size=40)
            ]),
            ink=True
        )

    def logout(self, e):
        self.page.client_storage.remove("supabase_token")
        self.page.client_storage.remove("user_role")
        self.page.go("/login")