import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY

class CaregiverDashboardView(ft.View):
    def __init__(self, page: ft.Page, user_name: str, auth_service):
        super().__init__(route="/dashboard/caregiver", bgcolor=BACKGROUND_LIGHT)
        self.page = page
        self.user_name = user_name
        self.auth_service = auth_service
        self.patients_data = [] 

        self.patients_column = ft.Column(scroll=ft.ScrollMode.ADAPTIVE)
        
        # --- Modal de Adicionar Paciente ---
        self.invite_email_field = ft.TextField(
            label="E-mail do Paciente", 
            hint_text="exemplo@email.com",
            border_color=ft.Colors.GREY_300,
            focused_border_color=PRIMARY
        )
        
        self.add_patient_dialog = ft.AlertDialog(
            title=ft.Text("Adicionar Paciente"),
            content=ft.Column([
                ft.Text("Insira o e-mail do paciente para conectar.", size=14, color=TEXT_MUTED),
                ft.Container(height=10),
                self.invite_email_field
            ], height=100, tight=True),
            actions=[
                ft.TextButton("Cancelar", on_click=self.close_dialog),
                ft.ElevatedButton("Enviar Convite", style=ft.ButtonStyle(bgcolor=PRIMARY, color=ft.Colors.WHITE), on_click=self.send_invite),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )

        # --- AppBar ---
        self.appbar = ft.AppBar(
            title=ft.Text("Início", color=TEXT_LIGHT, weight=ft.FontWeight.BOLD),
            bgcolor=ft.Colors.WHITE,
            elevation=0,
            center_title=True,
            automatically_imply_leading=False,
            actions=[
                ft.IconButton(ft.Icons.REFRESH, icon_color=TEXT_LIGHT, on_click=lambda e: self.load_patients()),
                ft.IconButton(ft.Icons.NOTIFICATIONS_OUTLINED, icon_color=TEXT_LIGHT)
            ]
        )

        # --- Conteúdo das Abas ---
        self.tabs_content = [
            self._view_patients(), 
            self._view_alerts(),   
            self._view_profile(),  
        ]

        self.body_container = ft.Container(
            content=self.tabs_content[0],
            expand=True,
            padding=20
        )

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

    def did_mount(self):
        self.load_patients()

    def load_patients(self):
        try:
            self.patients_column.controls = [ft.ProgressBar(width=100, color=PRIMARY)]
            self.update()

            user = self.auth_service.supabase.auth.get_user()
            my_id = user.user.id

            response = self.auth_service.supabase.table("caregiver_patient_links")\
                .select("*")\
                .eq("caregiver_id", my_id)\
                .execute()
            
            self.patients_data = response.data
            self.render_patients_list()

        except Exception as e:
            print(f"Erro ao carregar pacientes: {e}")
            try: self.page.open(ft.SnackBar(ft.Text("Erro ao carregar lista."), bgcolor=ft.Colors.RED))
            except: pass

    def render_patients_list(self):
        self.patients_column.controls.clear()

        if not self.patients_data:
            self.patients_column.controls.append(
                ft.Column([
                    ft.Container(height=50),
                    ft.Icon(ft.Icons.PERSON_OFF_OUTLINED, size=60, color=ft.Colors.GREY_300),
                    ft.Text("Nenhum paciente conectado.", color=TEXT_MUTED),
                    ft.Text("Adicione alguém para começar.", size=12, color=ft.Colors.GREY_400),
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER)
            )
        else:
            for item in self.patients_data:
                # --- CORREÇÃO 1: Nome ou Email ---
                # Tenta pegar 'patient_name' primeiro (você precisará salvar isso no banco ao aceitar),
                # senão usa o email.
                display_name = item.get("patient_name") or item.get("patient_email")
                status = item.get("status")
                
                # --- CORREÇÃO 2: Cores e Texto de Status ---
                if status == 'active':
                    status_text = "Ativo"
                    status_color = ft.Colors.GREEN
                elif status == 'rejected':
                    status_text = "Recusado"
                    status_color = ft.Colors.RED
                else:
                    status_text = "Pendente"
                    status_color = ft.Colors.ORANGE

                self.patients_column.controls.append(
                    self._patient_card(display_name, status_text, status_color)
                )
        
        self.update()

    def change_tab(self, e):
        index = e.control.selected_index
        self.body_container.content = self.tabs_content[index]
        titles = ["Meus Pacientes", "Alertas", "Meu Perfil"]
        self.appbar.title.value = titles[index]
        self.update()

    def open_add_patient_dialog(self, e):
        self.page.open(self.add_patient_dialog)

    def close_dialog(self, e):
        self.page.close(self.add_patient_dialog)

    def send_invite(self, e):
        email = self.invite_email_field.value
        if not email: return
        
        try:
            user = self.auth_service.supabase.auth.get_user()
            my_id = user.user.id
            my_email = user.user.email

            data = {
                "caregiver_id": my_id,
                "caregiver_name": self.user_name,
                "caregiver_email": my_email,
                "patient_email": email,
                "status": "pending",
                "type": "familiar"
            }
            
            self.auth_service.supabase.table("caregiver_patient_links").insert(data).execute()

            self.page.close(self.add_patient_dialog)
            self.page.open(ft.SnackBar(ft.Text(f"Convite enviado para {email}!"), bgcolor=ft.Colors.GREEN))
            
            # --- AJUSTE: Limpa o campo após enviar ---
            self.invite_email_field.value = ""
            self.invite_email_field.update()
            
            self.load_patients()

        except Exception as error:
            print(error)
            if "duplicate key" in str(error):
                self.page.open(ft.SnackBar(ft.Text("Você já convidou este paciente."), bgcolor=ft.Colors.ORANGE))
            else:
                self.page.open(ft.SnackBar(ft.Text("Erro ao enviar convite."), bgcolor=ft.Colors.RED))
        
        self.page.update()

    def _view_patients(self):
        return ft.Column(
            [
                ft.Text(f"Olá, {self.user_name}", size=28, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                ft.Text("Quem você quer acompanhar?", size=16, color=TEXT_MUTED),
                ft.Container(height=20),
                ft.Container(content=self.patients_column, height=400),
                ft.Container(height=20),
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
                    on_click=self.open_add_patient_dialog 
                )
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    def _view_alerts(self):
        return ft.Column(
            [
                ft.Text("Atividades Recentes", size=20, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                ft.Container(height=10),
                self._alert_tile("Sem alertas recentes", ft.Icons.CHECK_CIRCLE, ft.Colors.GREEN),
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    # --- AJUSTE: Perfil Completo ---
    def _view_profile(self):
        return ft.Column(
            [
                ft.Container(
                    alignment=ft.alignment.center,
                    content=ft.Column([
                        ft.CircleAvatar(
                            radius=50, 
                            bgcolor=ft.Colors.BLUE_50,
                            content=ft.Icon(ft.Icons.PERSON, size=50, color=PRIMARY)
                        ),
                        ft.Container(height=10),
                        ft.Text(self.user_name, size=22, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT),
                        ft.Text("Cuidador", color=TEXT_MUTED),
                    ], horizontal_alignment=ft.CrossAxisAlignment.CENTER)
                ),
                ft.Container(height=30),
                
                # Lista de Opções
                ft.Container(
                    bgcolor=ft.Colors.WHITE,
                    border_radius=12,
                    padding=10,
                    content=ft.Column([
                        ft.ListTile(
                            leading=ft.Icon(ft.Icons.PERSON_OUTLINE, color=PRIMARY), 
                            title=ft.Text("Meus Dados", color=TEXT_LIGHT),
                            trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT, color=TEXT_MUTED)
                        ),
                        ft.Divider(height=1, color=ft.Colors.GREY_100),
                        ft.ListTile(
                            leading=ft.Icon(ft.Icons.SETTINGS_OUTLINED, color=PRIMARY), 
                            title=ft.Text("Configurações", color=TEXT_LIGHT),
                            trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT, color=TEXT_MUTED)
                        ),
                        ft.Divider(height=1, color=ft.Colors.GREY_100),
                        ft.ListTile(
                            leading=ft.Icon(ft.Icons.HELP_OUTLINE, color=PRIMARY), 
                            title=ft.Text("Ajuda e Suporte", color=TEXT_LIGHT),
                            trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT, color=TEXT_MUTED)
                        ),
                    ])
                ),
                
                ft.Container(height=20),
                
                ft.Container(
                    bgcolor=ft.Colors.WHITE,
                    border_radius=12,
                    padding=10,
                    content=ft.ListTile(
                        leading=ft.Icon(ft.Icons.LOGOUT, color=ft.Colors.RED), 
                        title=ft.Text("Sair da Conta", color=ft.Colors.RED), 
                        on_click=self.logout
                    )
                ),
            ],
            scroll=ft.ScrollMode.ADAPTIVE
        )

    def _patient_card(self, name, status_text, status_color):
        return ft.Container(
            padding=15,
            margin=ft.margin.only(bottom=10),
            bgcolor=ft.Colors.WHITE,
            border_radius=12,
            border=ft.border.all(1, ft.Colors.GREY_200),
            content=ft.Column([
                ft.Row([
                    ft.CircleAvatar(
                        content=ft.Text(name[0].upper(), weight=ft.FontWeight.BOLD), 
                        bgcolor=ft.Colors.BLUE_50, 
                        color=PRIMARY
                    ),
                    ft.Container(width=10),
                    ft.Column([
                        ft.Text(name, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT, size=16),
                        ft.Text(status_text, color=status_color, size=12, weight=ft.FontWeight.BOLD),
                    ], expand=True),
                    ft.Icon(ft.Icons.CHEVRON_RIGHT, color=TEXT_MUTED)
                ]),
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