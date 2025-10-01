import base64
import yaml
import os

def update_ca_bundle(ca_cert_path, webhook_config_path):
    # Read and base64 encode the CA certificate
    with open(ca_cert_path, 'rb') as f:
        ca_cert_data = f.read()
    encoded_ca_cert = base64.b64encode(ca_cert_data).decode('utf-8')

    # Load the MutatingWebhookConfiguration YAML
    with open(webhook_config_path, 'r') as f:
        webhook_config = yaml.safe_load(f)

    # Update the caBundle
    if 'webhooks' in webhook_config and len(webhook_config['webhooks']) > 0:
        webhook_config['webhooks'][0]['clientConfig']['caBundle'] = encoded_ca_cert
    else:
        raise ValueError("MutatingWebhookConfiguration does not contain a webhook definition.")

    # Write the updated YAML back to the file
    with open(webhook_config_path, 'w') as f:
        yaml.dump(webhook_config, f, default_flow_style=False)

    print(f"Successfully updated caBundle in {webhook_config_path}")

if __name__ == "__main__":
    base_dir = "."
    ca_cert_file = os.path.join(base_dir, "ca.crt")
    webhook_config_file = os.path.join(base_dir, "mutatingwebhookconfiguration.yaml")

    update_ca_bundle(ca_cert_file, webhook_config_file)
