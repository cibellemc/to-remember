import flet as ft
from common.colors import BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED, PRIMARY
from presentation.components.action_button import ActionButton

class RegisterSpecificsView(ft.View):
    def __init__(self, page: ft.Page, role: str, basic_data: dict, auth_service):
        super().__init__(route=f"/register/step3/{role}", bgcolor=BACKGROUND_LIGHT)
        self.page = page
        self.role = role
        self.basic_data = basic_data 
        self.auth_service = auth_service
        
        # --- Tradução do Título ---
        role_title = "Paciente" if role == "patient" else "Cuidador"

        # --- AppBar ---
        self.appbar = ft.AppBar(
            leading=ft.IconButton(
                ft.Icons.ARROW_BACK, 
                on_click=lambda e: self.page.go(f"/register/step2/{role}"),
                icon_color=TEXT_LIGHT
            ),
            title=ft.Column(
                [
                    ft.Text(f"Perfil do {role_title}", color=TEXT_LIGHT, weight=ft.FontWeight.BOLD, size=18),
                    ft.Text("Último passo", color=TEXT_MUTED, size=12),
                ], 
                spacing=0, 
                alignment=ft.MainAxisAlignment.CENTER
            ),
            center_title=True,
            bgcolor=ft.Colors.WHITE,
            elevation=0
        )

        # --- Header Visual (Substituindo a foto) ---
        # Um ícone grande e centralizado para preencher o espaço visualmente
        icon_name = ft.Icons.MEDICAL_SERVICES_OUTLINED if role == "caregiver" else ft.Icons.ELDERLY
        
        header_icon = ft.Container(
            content=ft.Column([
                ft.Container(
                    content=ft.Icon(icon_name, size=60, color=PRIMARY),
                    padding=20,
                    bgcolor=ft.Colors.with_opacity(0.1, PRIMARY), # Fundo suave
                    border_radius=50,
                ),
                ft.Container(height=10),
                ft.Text(
                    "Quase lá! Precisamos apenas de\nalguns detalhes finais.", 
                    color=TEXT_MUTED, 
                    size=14, 
                    text_align=ft.TextAlign.CENTER
                )
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
            alignment=ft.alignment.center,
            padding=ft.padding.only(bottom=30)
        )

        # --- Campos Dinâmicos ---
        self.specific_content = ft.Column(spacing=20) 

        # Helper para estilo consistente e alto contraste
        def field_style(label_text):
            return {
                "label": label_text,
                "label_style": ft.TextStyle(color=TEXT_LIGHT, size=14), # Contraste corrigido
                "text_style": ft.TextStyle(color=TEXT_LIGHT),
                "border_color": ft.Colors.GREY_400,
                "focused_border_color": PRIMARY,
                "text_size": 16
            }

        if self.role == "caregiver":
            # Dropdown (Largura corrigida)
            self.caregiver_type = ft.Dropdown(
                label="Tipo de Cuidador",
                options=[
                    ft.dropdown.Option("Familiar"),
                    ft.dropdown.Option("Profissional"),
                ],
                label_style=ft.TextStyle(color=TEXT_LIGHT, size=14), # Contraste corrigido
                text_style=ft.TextStyle(color=TEXT_LIGHT),
                border_color=ft.Colors.GREY_400,
                focused_border_color=PRIMARY,
                width=float('inf'), # <--- CORREÇÃO: Ocupa toda a largura disponível
                on_change=self.on_caregiver_type_change 
            )
            
            # Familiar
            self.relation_field = ft.TextField(
                **field_style("Grau de Parentesco (Ex: Filho)"),
                visible=False,
            )
            self.is_main_caregiver = ft.Checkbox(
                label="Sou o cuidador principal", 
                active_color=PRIMARY, 
                visible=False,
                label_style=ft.TextStyle(color=TEXT_LIGHT), # Contraste corrigido
            )
            
            # Profissional
            self.crm_field = ft.TextField(
                **field_style("Número do CRM"),
                visible=False,
            )
            self.specialty_field = ft.TextField(
                **field_style("Especialidade (Ex: Geriatra)"),
                visible=False,
            )

            self.specific_content.controls = [
                self.caregiver_type,
                self.relation_field,
                self.is_main_caregiver,
                self.crm_field,
                self.specialty_field
            ]

        elif self.role == "patient":
            self.phone_field = ft.TextField(
                **field_style("Telefone"),
                keyboard_type=ft.KeyboardType.PHONE
            )
            self.birth_date = ft.TextField(
                **field_style("Data de Nascimento (DD/MM/AAAA)"),
                keyboard_type=ft.KeyboardType.DATETIME
            )
            self.specific_content.controls = [
                self.phone_field,
                self.birth_date
            ]

        # --- Botão Finalizar ---
        self.finish_button = ActionButton(
            text="Finalizar Cadastro",
            on_click=self.finalize_registration
        )
        self.finish_button.padding = ft.padding.symmetric(horizontal=40)

        # Layout Final
        self.controls = [
            ft.Container(
                content=ft.Column(
                    [
                        ft.Container(height=10),
                        header_icon, # Novo cabeçalho visual
                        self.specific_content,
                        ft.Container(height=30),
                        self.finish_button
                    ],
                    scroll=ft.ScrollMode.ADAPTIVE,
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                ),
                padding=30,
                expand=True
            )
        ]

    def on_caregiver_type_change(self, e):
        tipo = self.caregiver_type.value
        
        # Reseta visibilidade
        self.relation_field.visible = False
        self.is_main_caregiver.visible = False
        self.crm_field.visible = False
        self.specialty_field.visible = False

        if tipo == "Familiar":
            self.relation_field.visible = True
            self.is_main_caregiver.visible = True
        elif tipo == "Profissional":
            self.crm_field.visible = True
            self.specialty_field.visible = True
        
        self.update()

    def finalize_registration(self, e):
        try:
            self.finish_button.content.disabled = True
            self.finish_button.update()
            
            # Não fazemos mais upload de foto aqui

            # 2. Coletar dados extras
            extra_data = {}
            if self.role == "caregiver":
                extra_data["type"] = self.caregiver_type.value
                
                if self.caregiver_type.value == "Familiar":
                    if not self.relation_field.value:
                         raise Exception("Informe o grau de parentesco.")
                    extra_data["relation"] = self.relation_field.value
                    extra_data["is_main"] = self.is_main_caregiver.value
                
                elif self.caregiver_type.value == "Profissional":
                    if not self.crm_field.value:
                         raise Exception("Informe o CRM.")
                    extra_data["crm"] = self.crm_field.value
                    extra_data["specialty"] = self.specialty_field.value
            
            elif self.role == "patient":
                extra_data["phone"] = self.phone_field.value
                extra_data["birth_date"] = self.birth_date.value

            # 3. Registrar no Supabase
            print("Registrando usuário...")
            self.auth_service.register(
                name=self.basic_data['name'],
                email=self.basic_data['email'],
                password=self.basic_data['password'],
                role=self.role,
                extra_data=extra_data
            )

            self.page.open(ft.SnackBar(ft.Text("Sucesso!"), bgcolor=ft.Colors.GREEN))
            self.page.go("/login") 

        except Exception as error:
            self.page.open(ft.SnackBar(ft.Text(f"Erro: {error}"), bgcolor=ft.Colors.RED))
        finally:
            self.finish_button.content.disabled = False
            self.finish_button.update()