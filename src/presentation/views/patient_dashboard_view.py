import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY

class PatientDashboardView(ft.View):
    # ADICIONADO: auth_service no construtor
    def __init__(self, page: ft.Page, user_name: str, auth_service):
        super().__init__(route="/dashboard/patient", bgcolor=BACKGROUND_LIGHT)
        self.page = page
        self.user_name = user_name
        self.auth_service = auth_service
        self.caregivers_requests = []
        self.caregivers_connected = []

        # Containers de lista
        self.requests_column = ft.Column()
        self.connected_column = ft.Column()

        self.appbar = ft.AppBar(
            title=ft.Text("Início", color=TEXT_LIGHT, weight=ft.FontWeight.BOLD),
            bgcolor=ft.Colors.WHITE,
            elevation=0,
            center_title=True,
            automatically_imply_leading=False,
            actions=[ft.IconButton(ft.Icons.REFRESH, icon_color=TEXT_LIGHT, on_click=lambda e: self.load_network())]
        )

        self.tabs_content = [
            self._view_games(),
            self._view_progress(),
            self._view_caregivers(),
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
                ft.NavigationBarDestination(icon=ft.Icons.PEOPLE_OUTLINE, selected_icon=ft.Icons.PEOPLE, label="Rede"), 
                ft.NavigationBarDestination(icon=ft.Icons.PERSON_OUTLINE, selected_icon=ft.Icons.PERSON, label="Perfil"),
            ]
        )
        self.controls = [self.body_container]

    def did_mount(self):
        self.load_network()

    def load_network(self):
        try:
            user = self.auth_service.supabase.auth.get_user()
            my_email = user.user.email

            # Busca links onde o paciente é este usuário (pelo email)
            response = self.auth_service.supabase.table("caregiver_patient_links")\
                .select("*")\
                .eq("patient_email", my_email)\
                .execute()
            
            links = response.data
            
            # Separa em pendentes e ativos
            self.caregivers_requests = [l for l in links if l['status'] == 'pending']
            self.caregivers_connected = [l for l in links if l['status'] == 'active']
            
            self.render_network()

        except Exception as e:
            print(f"Erro rede: {e}")

    def render_network(self):
        self.requests_column.controls.clear()
        self.connected_column.controls.clear()

        # Renderiza Solicitações
        if not self.caregivers_requests:
            self.requests_column.controls.append(ft.Text("Nenhuma solicitação pendente.", size=12, color=TEXT_MUTED))
        else:
            for req in self.caregivers_requests:
                name = req.get("caregiver_name", "Cuidador")
                link_id = req.get("id")
                self.requests_column.controls.append(self._request_card(name, "Quer conectar", link_id))

        # Renderiza Conectados
        if not self.caregivers_connected:
            self.connected_column.controls.append(ft.Text("Nenhum cuidador conectado.", size=12, color=TEXT_MUTED))
        else:
            for conn in self.caregivers_connected:
                name = conn.get("caregiver_name", "Cuidador")
                self.connected_column.controls.append(self._caregiver_card(name, "Conectado"))
        
        self.update()

    def update_invite_status(self, link_id, status):
        try:
            self.auth_service.supabase.table("caregiver_patient_links")\
                .update({"status": status})\
                .eq("id", link_id)\
                .execute()
            
            msg = "Convite aceito!" if status == 'active' else "Convite recusado."
            self.page.open(ft.SnackBar(ft.Text(msg), bgcolor=ft.Colors.GREEN if status == 'active' else ft.Colors.RED))
            self.load_network() # Recarrega
        except Exception as e:
            self.page.open(ft.SnackBar(ft.Text(f"Erro: {e}"), bgcolor=ft.Colors.RED))

    def _view_caregivers(self):
        return ft.Column(
            [
                ft.Text("Minha Rede", size=24, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                ft.Container(height=10),
                
                ft.Text("Solicitações", weight=ft.FontWeight.BOLD, color=PRIMARY, size=14),
                ft.Container(height=5),
                self.requests_column,
                
                ft.Divider(height=30, color=ft.Colors.GREY_200),
                
                ft.Text("Cuidadores Conectados", weight=ft.FontWeight.BOLD, color=TEXT_LIGHT, size=14),
                ft.Container(height=5),
                self.connected_column,
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    def _request_card(self, name, relation, link_id):
        return ft.Container(
            padding=15, margin=ft.margin.only(bottom=10), bgcolor=ft.Colors.WHITE, border_radius=16,
            content=ft.Column([
                ft.Row([
                    ft.CircleAvatar(content=ft.Text(name[0], weight=ft.FontWeight.BOLD), bgcolor=ft.Colors.ORANGE_100, color=ft.Colors.ORANGE_800),
                    ft.Container(width=10),
                    ft.Column([ft.Text(name, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT), ft.Text(relation, color=TEXT_MUTED, size=12)], expand=True),
                ]),
                ft.Container(height=10),
                ft.Row([
                    ft.ElevatedButton("Aceitar", style=ft.ButtonStyle(bgcolor=PRIMARY, color=ft.Colors.WHITE), expand=True, on_click=lambda e: self.update_invite_status(link_id, "active")),
                    ft.Container(width=10),
                    ft.OutlinedButton("Recusar", expand=True, on_click=lambda e: self.update_invite_status(link_id, "rejected")),
                ])
            ])
        )

    def _caregiver_card(self, name, relation):
        return ft.Container(
            padding=15, margin=ft.margin.only(bottom=10), bgcolor=ft.Colors.WHITE, border_radius=16,
            content=ft.Row([
                ft.CircleAvatar(content=ft.Text(name[0]), bgcolor=ft.Colors.BLUE_50, color=PRIMARY),
                ft.Container(width=10),
                ft.Column([ft.Text(name, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT), ft.Text(relation, color=TEXT_MUTED, size=12)], expand=True),
                ft.Icon(ft.Icons.CHECK_CIRCLE, color=ft.Colors.GREEN)
            ])
        )

    def change_tab(self, e):
        index = e.control.selected_index
        self.body_container.content = self.tabs_content[index]
        self.appbar.title.value = ["Jogos", "Meu Progresso", "Minha Rede", "Meu Perfil"][index]
        self.update()

    # ... (Mantenha _view_games, _view_progress, _view_profile do código anterior)
    def _view_games(self): return ft.Text("Jogos") # Simplificado para o exemplo, mantenha o seu
    def _view_progress(self): return ft.Text("Progresso")
    def _view_profile(self): return ft.Text("Perfil")