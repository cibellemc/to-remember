import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY, BACKGROUND_DARK

class DashboardView(ft.View):
    def __init__(self, page: ft.Page, role: str, user_name: str = ""):
        super().__init__(route=f"/dashboard/{role}", bgcolor=BACKGROUND_LIGHT)
        self.page = page
        self.role = role
        # Se não vier nome, usa um fallback amigável
        self.user_name = user_name if user_name else ("Paciente" if role == "patient" else "Cuidador")
        
        # --- Lógica de Decisão de Conteúdo ---
        # Aqui decidimos se montamos a tela de Paciente ou Cuidador
        if self.role == "patient":
            self.tabs_content = self._build_patient_tabs()
            self.nav_destinations = self._build_patient_nav()
        else:
            self.tabs_content = self._build_caregiver_tabs()
            self.nav_destinations = self._build_caregiver_nav()

        # --- AppBar ---
        self.appbar = ft.AppBar(
            title=ft.Text("Início", color=TEXT_LIGHT, weight=ft.FontWeight.BOLD),
            bgcolor=ft.Colors.WHITE,
            elevation=0,
            center_title=True,
            automatically_imply_leading=False, # Remove seta de voltar
        )

        # --- Corpo ---
        self.body_container = ft.Container(
            content=self.tabs_content[0], # Começa na primeira aba
            expand=True,
            padding=20
        )

        # --- Navegação Inferior ---
        self.navigation_bar = ft.NavigationBar(
            selected_index=0,
            on_change=self.change_tab,
            bgcolor=ft.Colors.WHITE,
            indicator_color=ft.Colors.with_opacity(0.2, PRIMARY),
            destinations=self.nav_destinations
        )

        self.controls = [self.body_container]

    def change_tab(self, e):
        index = e.control.selected_index
        self.body_container.content = self.tabs_content[index]
        
        # Atualiza título da AppBar (Lógica simplificada)
        titles = [d.label for d in self.nav_destinations]
        self.appbar.title.value = titles[index]
        self.update()

    # =================================================================
    #                       CONFIGURAÇÃO DO PACIENTE
    # =================================================================
    
    def _build_patient_nav(self):
        return [
            ft.NavigationBarDestination(icon=ft.Icons.GAMEPAD_OUTLINED, selected_icon=ft.Icons.GAMEPAD, label="Jogos"),
            ft.NavigationBarDestination(icon=ft.Icons.BAR_CHART_OUTLINED, selected_icon=ft.Icons.BAR_CHART, label="Progresso"),
            ft.NavigationBarDestination(icon=ft.Icons.PERSON_OUTLINE, selected_icon=ft.Icons.PERSON, label="Perfil"),
        ]

    def _build_patient_tabs(self):
        return [
            self._view_patient_home(),      # Aba 0
            self._view_patient_progress(),  # Aba 1
            self._view_profile(),           # Aba 2 (Comum)
        ]

    def _view_patient_home(self):
        return ft.Column(
            [
                ft.Text(f"Olá, {self.user_name}!", size=28, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                ft.Text("Vamos exercitar a mente?", size=16, color=TEXT_MUTED),
                ft.Container(height=20),
                self._game_card("Memória", ft.Icons.MEMORY, "Encontre os pares", ft.Colors.BLUE),
                self._game_card("Lógica", ft.Icons.LIGHTBULB, "Resolva os desafios", ft.Colors.ORANGE),
                self._game_card("Foco", ft.Icons.CENTER_FOCUS_STRONG, "Atenção plena", ft.Colors.PURPLE),
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    def _view_patient_progress(self):
        return ft.Column([
            ft.Text("Seu Desempenho", size=24, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
            ft.Container(height=20),
            # Placeholder de gráfico
            ft.Container(
                height=200, 
                bgcolor=ft.Colors.WHITE, 
                border_radius=16,
                content=ft.Column([
                    ft.Text("Pontuação da Semana", color=TEXT_MUTED),
                    ft.Text("1.250 pts", size=30, weight=ft.FontWeight.BOLD, color=PRIMARY)
                ], alignment=ft.MainAxisAlignment.CENTER, horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                alignment=ft.alignment.center
            )
        ])

    # =================================================================
    #                       CONFIGURAÇÃO DO CUIDADOR
    # =================================================================

    def _build_caregiver_nav(self):
        return [
            ft.NavigationBarDestination(icon=ft.Icons.PEOPLE_OUTLINE, selected_icon=ft.Icons.PEOPLE, label="Pacientes"),
            ft.NavigationBarDestination(icon=ft.Icons.NOTIFICATIONS_OUTLINED, selected_icon=ft.Icons.NOTIFICATIONS, label="Alertas"),
            ft.NavigationBarDestination(icon=ft.Icons.PERSON_OUTLINE, selected_icon=ft.Icons.PERSON, label="Perfil"),
        ]

    def _build_caregiver_tabs(self):
        return [
            self._view_caregiver_patients(), # Aba 0
            self._view_caregiver_alerts(),   # Aba 1
            self._view_profile(),            # Aba 2 (Comum)
        ]

    def _view_caregiver_patients(self):
        return ft.Column(
            [
                ft.Text(f"Olá, {self.user_name}", size=28, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                ft.Text("Quem você quer acompanhar?", size=16, color=TEXT_MUTED),
                ft.Container(height=20),
                # Lista de Pacientes (Exemplo estático por enquanto)
                self._patient_card("Maria Silva", "Mãe", "Último jogo: Hoje"),
                self._patient_card("João Pereira", "Pai", "Último jogo: Ontem"),
                
                ft.Container(height=20),
                ft.OutlinedButton(
                    "Adicionar Novo Paciente", 
                    icon=ft.Icons.ADD,
                    style=ft.ButtonStyle(color=PRIMARY),
                    width=float('inf')
                )
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    def _view_caregiver_alerts(self):
        return ft.Column([
            ft.Text("Alertas Recentes", size=24, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
            ft.Container(height=10),
            ft.ListTile(
                leading=ft.Icon(ft.Icons.WARNING_AMBER, color=ft.Colors.ORANGE),
                title=ft.Text("Maria Silva não jogou hoje"),
                subtitle=ft.Text("Sugerir atividade?")
            )
        ])

    # =================================================================
    #                       COMPONENTES COMUNS
    # =================================================================

    def _view_profile(self):
        return ft.Column(
            [
                ft.Container(
                    alignment=ft.alignment.center,
                    content=ft.Column([
                        ft.CircleAvatar(radius=50, content=ft.Icon(ft.Icons.PERSON, size=50)),
                        ft.Text(self.user_name, size=22, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                        ft.Text("Configurações da Conta", color=TEXT_MUTED),
                    ], horizontal_alignment=ft.CrossAxisAlignment.CENTER)
                ),
                ft.Container(height=30),
                ft.ListTile(leading=ft.Icon(ft.Icons.LOGOUT, color=ft.Colors.RED), title=ft.Text("Sair", color=ft.Colors.RED), on_click=self.logout),
            ]
        )

    def _game_card(self, title, icon, subtitle, color):
        return ft.Container(
            padding=20,
            margin=ft.margin.only(bottom=15),
            bgcolor=ft.Colors.WHITE,
            border_radius=16,
            content=ft.Row([
                ft.Container(
                    content=ft.Icon(icon, color=color, size=30),
                    bgcolor=ft.Colors.with_opacity(0.1, color),
                    padding=12,
                    border_radius=12
                ),
                ft.Container(width=15),
                ft.Column([
                    ft.Text(title, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT, size=18),
                    ft.Text(subtitle, color=TEXT_MUTED, size=13),
                ], expand=True),
                ft.Icon(ft.Icons.CHEVRON_RIGHT, color=TEXT_MUTED)
            ]),
            ink=True,
            on_click=lambda e: print(f"Abrir jogo {title}")
        )

    def _patient_card(self, name, relation, status):
        return ft.Container(
            padding=15,
            margin=ft.margin.only(bottom=10),
            bgcolor=ft.Colors.WHITE,
            border_radius=12,
            border=ft.border.all(1, ft.Colors.GREY_200),
            content=ft.Row([
                ft.CircleAvatar(content=ft.Text(name[0], color=ft.Colors.WHITE), bgcolor=PRIMARY),
                ft.Container(width=15),
                ft.Column([
                    ft.Text(name, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                    ft.Text(relation, color=TEXT_MUTED, size=12),
                ], expand=True),
                ft.Column([
                    ft.Text(status, size=10, color=TEXT_MUTED, text_align=ft.TextAlign.RIGHT),
                ])
            ]),
            ink=True
        )

    def logout(self, e):
        self.page.client_storage.remove("supabase_token")
        self.page.client_storage.remove("user_role")
        self.page.go("/login")