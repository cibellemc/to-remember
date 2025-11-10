import flet as ft

class DashboardView(ft.View):
    def __init__(self, page: ft.Page, role: str):
        super().__init__(route=f"/dashboard/{role}")
        self.page = page
        self.role = role

        if role == "patient":
            content = self.build_patient_dashboard()
        else:
            content = self.build_caregiver_dashboard()

        self.controls = [
            ft.AppBar(title=ft.Text(f"Dashboard ({role})"), bgcolor=ft.Colors.ON_SURFACE_VARIANT),
            content
        ]
        
    def build_patient_dashboard(self):
        return ft.Container(
            content=ft.Column(
                [
                    ft.Text("Bem-vindo, Paciente!", size=20),
                    ft.ElevatedButton("Começar Jogo", on_click=lambda e: self.page.go("/game")), # Rota futura
                    ft.ElevatedButton("Ver Relatórios", on_click=lambda e: self.page.go("/reports")), # Rota futura
                ],
                alignment=ft.MainAxisAlignment.CENTER,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            alignment=ft.alignment.center,
            expand=True
        )

    def build_caregiver_dashboard(self):
        return ft.Container(
            content=ft.Text("Bem-vindo, Cuidador! (Aqui ficará sua lista de pacientes)"),
            alignment=ft.alignment.center,
            expand=True
        )