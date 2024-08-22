import os
import pandas as pd
from jinja2 import Template

parent_dir = os.path.dirname(os.path.abspath(__file__))

excel_file_path = os.path.join(parent_dir, 'OCI.xlsx')
template_file_path = os.path.abspath(os.path.join(parent_dir, '..', 'IAM', 'template', 'IAM.j2'))
output_file_path =os.path.abspath(os.path.join(parent_dir, '..', 'IAM', 'variables.tfvars'))

compartments_df = pd.read_excel(excel_file_path, sheet_name='Compartments')
groups_df = pd.read_excel(excel_file_path, sheet_name='Groups')

compartments = []
for index, row in compartments_df.iterrows():
    compartment = {
        'name': row['Name'],
        'description': row['Description'],
        'location': row['Region']
    }
    compartments.append(compartment)

groups = []
for index, row in groups_df.iterrows():
    #members = row['U_ids'].split(',') if isinstance(row['U_ids'], str) else []
    if isinstance(row['U_ids'], str):
        members = [member.strip() for member in row['U_ids'].split(',')]
    else:
        members = []
    group = {
        'name': row['Name'],
        'description': row['Description'],
        'members': members
    }
    groups.append(group)

data = {
    'location': compartments[0]['location'] if compartments else '',
    'compartments': compartments,
    'group_config': groups
}

with open(template_file_path, 'r') as file:
    template_content = file.read()

template = Template(template_content)

rendered_template = template.render(data)

with open(output_file_path, 'w') as file:
    file.write(rendered_template)

print("Le contenu a été écrit dans le fichier variables.tfvars avec succès.")
