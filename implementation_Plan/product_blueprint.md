# **Product Requirements Document (PRD): Agent-First Property Management OS**

## **1\. Product Overview**

This product is a headless, AI-first Property Management assistant that’s a highly automated, agent-driven backend. The system connects property data, tenant context, and legal compliance into autonomous workflows, communicating with human managers via an "Email ➔ Text/WhatsApp ➔ Phone" escalation router.

The vision of the product is to make it accessible to realtors’ own preferred AI agents, such as OpenClaw, or Manus, SaaS or customized UI powered by AI/LLM. 

## **2\. Target Audience & Personas**

* **Primary User:** Property Managers & Real Estate Agents.  
* **Secondary User:** The "9-Person Ownership Team" / "The Boss" (requires high-level, context-rich summaries for final approvals).  
* **End User:** Tenants (interacting via email, SMS, WhatsApp, and web forms).  
* **External Actors:** Trade Workers / Vendors (plumbers, electricians).

## **3\. Core Use Cases & Functional Requirements**

### **Use Case 1: Proactive Rent Adjustment & Client Care**

**Problem:** Tracking 12-month lease cycles manually and researching market comparables is time-consuming.

**Trigger:** Cron job detects a lease is 4 months away from its 12-month anniversary.

**Functional Requirements:**

* **Market Review (MKT Review):** The AI must autonomously scrape local market data to determine current rental rates.  
* **Legal Calculation:** The system must calculate the maximum allowable rent increase based on local guidelines (e.g., Ontario's 2026 rent increase guideline is 2.1%).  
* **Advice Generation:** Generate a "Rent Adjustment Advice" brief for the property manager outlining the current rent, market rent, legal limit, and a final recommendation.  
* **Client Care (Birthdays & Cheques):** The system must track tenant birthdays and generate personalized e-cards for manager approval. It must also monitor the 12-month post-dated cheque supply and flag accounts requiring a "cheque checkup."  
* **Client Care Route:** Based on queries, AI will automatically design and assign property check routes to property managers for regular check-ups, pick up cheques, fix requires and routine check-ups. All assigned properties must contain confirmation from the tenant. 

### **Use Case 2: Multi-Modal Maintenance Triage**

**Problem:** Tenants submit vague maintenance requests that require managers to hunt down appliance model numbers and manually text contractors.

**Trigger:** Tenant uploads a video or photo of an issue via WhatsApp or Email.

**Functional Requirements:**

* **Vision Analysis:** The AI must process the text first. Then, if needed, video/image to identify the issue and cross-reference the Properties database to extract the exact "electronic model & number" of the affected appliance.  
* **Vendor Routing:** The AI must match the issue to the appropriate "trade worker" profile based on expertise, location and provide a list of appropriate trade workers.  
* **Emergency Bypass:** If the AI detects keywords or visuals matching "sudden deal w/: water pipe" or "basement flood," it must bypass the standard queue and immediately trigger an emergency phone/SMS/WhatsApp alert to the property manager.  
* **Approval & Dispatch:** Draft a work order and appointment time. Upon manager approval, dispatch the request to the worker via SMS/WhatsApp.

### **Use Case 3: Automated Legal Compliance & Form Generation**

**Problem:** Missing rent requires strict adherence to legal timelines and perfectly filled-out government forms.

**Trigger:** Rent is flagged as missing in the ledger, or a manager requests an eviction notice.

**Functional Requirements:**

* **Form Mapping:** The system must automatically pull data from the database and map it to the exact fields required for Ontario Landlord and Tenant Board forms.  
* **Supported Forms:** Must support automated PDF generation for:  
  * **N4:** Notice to End a Tenancy for Non-Payment of Rent.  
  * **N9:** Tenant's Notice to End the Tenancy.  
  * **N12:** Notice to End Tenancy for Landlord's Own Use.  
* **PDF Editing:** The system must be able to edit PDF with appropriate tenant names, address or any other required fields from the forms (N4, N9, N12).  
* **Expense Tracking:** The system must track all repair expenses (with tax) and automatically generate a unified report to send to the property owner.

### **Use Case 4: Context-Rich CRM Escalation**

**Problem:** When an issue requires owner approval, the "Boss" lacks the immediate context of the tenant's history and property financials.

**Trigger:** A manager clicks "Escalate to Boss" on a specific ticket.

**Functional Requirements:**

* **Context Aggregation:** The AI must query the relational database and pull the complete historical context.  
* **Property Profile Extraction:** Must include Address, Current Rent, Status, Fix history, Landlord Name, Expense history, and offline management fees.  
* **Renter Profile Extraction:** Must include Name, Birthday, Last rent adjustment date, 12-month rent total, lease renewal window (e.g., 20 days), and highly personalized notes (e.g., "new parents, newly married").  
* **Summarization:** The AI must synthesize this data into a concise, 3-bullet-point "Escalation Brief" and deliver it to the 9-person team via Slack, Email, or WhatsApp.

## **4\. Data Architecture (Supabase Schema)**

To support the AI's contextual memory, the database must be relational and time-stamped.

* **Table 1:** Properties  
* **AI Purpose:** Used by AI to fetch model numbers for maintenance and calculate owner expenses.  
* **Core Fields:**  
  * address: property address without postal code. Example: 44 Addison St   
  * city: the city name the property is located in. Example: Richmond Hill,   
  * province/state: the province or state name the property is located in. Example: Ontario   
  * postalcode: the postal code the property is located in. Example: L4C9N1  
  * property\_id: a random ID the system assigned to this property when it’s entered.   
  * landlord\_name: the name of the landlord of the property. Example: Joe Doe  
  * rent: current amount of rent of the property per month. Example: 1500  
  * status: the current status of the property. includes:   
    * normal: no outstanding issues of the property. No action triggered  
    * late\_payment: the rent payment is late from the tenant or problems with rent payments. This status gets triggered by Use Case 3\.  
    * fix\_needed: the property requires fix. This status gets triggered by Use Case 2\.   
  * fix: this field contains details of the fix, it’s a string field where whatever it makes sense, numbers, strings, special characters.  
  * note: this field contains any additional notes that are input by property managers or anyone who has system access. It’s a string field where whatever it makes sense, numbers, strings, special characters.  
  * time\_stamp: time stamp of any changes on this table. Format: dd/mm/yyyy

* **Table 2:** Tenant  
* **AI Purpose:** Queried by AI for BANT qualification, lease renewal timelines, and context injection.  
* **Core Fields:**  
  * address: property address without postal code. Example: 44 Addison St   
  * city: the city name the property is located in. Example: Richmond Hill,   
  * province/state: the province or state name the property is located in. Example: Ontario   
  * postalcode: the postal code the property is located in. Example: L4C9N1  
  * property\_id: a random ID the system assigned to this property when it’s entered.   
  * name: name of the tenant. Example: Joe Doe  
  * tenant\_id: a random ID the system assigned to this tenant when it’s entered.   
  * phone: phone number of the tenant. Example: 4161231234  
  * email: email of the tenant. Example test@gmail.com  
  * lease\_start: the start date of the lease. Format: dd/mm/yyyy  
  * rent\_amount: the amount of the rent per month. Example: 1500  
  * birthday: the birthday of the tenant. Format: dd/mm/yyyy  
  * last\_time\_rent\_adjustment\_date: the date of last rent adjustment. Format: dd/mm/yyyy  
  * note: this field contains any additional notes that are input by property managers or anyone who has system access including AI. It’s a string field where whatever it makes sense, numbers, strings, special characters.  
  * time\_stamp: time stamp of any changes on this table. Format: dd/mm/yyyy  
* **Table 3:** Interactions  
* **AI Purpose:** Provides the AI with a "Communication Log" to prevent repetitive questioning.  
* **Core Fields:**  
  * name: name of the tenant. Example: Joe Doe. The name must be the same name as the Tenant table.  
  * tenant\_id: a random ID the system assigned to this tenant when it’s entered. Must be consistent with the tenant\_id in the Tenant table.  
  * channel: The channels the tenant has been reached out to. Example: email  
  * timestamp: time stamp of any changes on this table. Format: dd/mm/yyyy  
  * Summary: This field contains any additional notes that are input by property managers or anyone who has system access including AI. It’s a string field where whatever it makes sense, numbers, strings, special characters.  
* **Table 4:** Maintenance  
* **AI Purpose:** Tracks the lifecycle of a fix from tenant video to contractor invoice.  
* **Core Fields:**   
  * property\_id: a random ID the system assigned to this property when it’s entered. Must be the same as the   
  * property\_address: property address without postal code. Example: 44 Addison St.   
  * issue\_type: the type of the issue by category. Values are only from the following options: Improper Surface Grading, water damage, electrical damage, appliance, roof, HVAC, and maintenance.  
  * prove: damage picture and/or video, fix picture and/or video urls.  
  * status: the status of the fix. Values are only from the following options: problem raised, waiting, assigned, fixing, solved  
  * assigned\_worker: the assigned business for the issue. For example: abc HVAC System Fixing Co.

## **5\. Non-Functional Requirements**

* **Architecture:**   
* **Security (Multi-Tenancy):** Supabase Row Level Security (RLS) must be strictly enforced so the AI agent for "Brokerage A" cannot query the tenant data of "Brokerage B".  
* **AI Access:** The system will operate as an MCP (Model Context Protocol) server. Instead of a traditional UI, the SaaS exposes its endpoints to the client's preferred AI agents (like Manus or OpenClaw) via a downloadable `SKILL.md` instruction file.  
* **Human-in-the-Loop (HITL):** The AI cannot autonomously take action such as sending a fix requirement to a trade worker, sending legally binding forms (N4/N12) or authorizing financial expenses without a manager sending an "Approve" message. The AI can only provide context, suggestions and suggested next steps.

### **1\. Why You Must Fork (Based on Your Images)**

* **Custom System Logic (`SOUL.md` & `HEARTBEAT.md`):** Your notes in Image 1 require the agent to automatically trigger "3-4 Mo ahead" of a 12-month rent adjustment. You need to push a custom `HEARTBEAT.md` file to your repository that contains the exact cron-job schedule to wake the AI up to perform this market review.  
* **Custom Legal Skills (`SKILL.md`):** Generating official Ontario LTB forms (N4, N12) requires custom Python or Node.js scripts to map database fields perfectly to PDFs. You must bake these custom skills directly into your repository so the agent has them installed by default.

### **2\. How to Add Authorization for the 9-Person Team**

OpenClaw is a highly privileged system. If you deploy it to the cloud, you must lock it down so only your team can access it. In your forked repository, you will configure two layers of security:

**Layer 1: Communication Allowlists (For Telegram/WhatsApp)** Image 2 notes that your team communicates via "text, phone, person." To ensure tenants or strangers cannot accidentally text your AI and issue commands, you must edit the configuration files in your fork to include an `allowFrom` array. You will list the specific phone numbers or Chat IDs of your 9 team members, instructing the Gateway to completely ignore messages from anyone else.

**Layer 2: Gateway Authentication (For the Web UI)** To secure the backend where the "Boss" might review the "Escalation" summaries:

* In your `openclaw.json` configuration file, you must set the authentication mode to `"token"`.  
* For a true multi-user business setup, security engineers recommend placing OpenClaw behind a "Reverse Proxy" (like HAProxy or Nginx) using HTTP Basic Authentication. This forces anyone trying to access the dashboard to log in with a username and password before they even reach the AI's gateway.

## **6\. Implementation Plan**

### **Architectural Blueprint and Implementation Strategy for an AI-First Property Management SaaS via OpenClaw**

#### **6.1. Strategic Architecture (Model Context Protocol)**

* **Adopting MCP:** To make the SaaS universally accessible to any external AI agent (Manus, Claude Code, etc.), the backend must use the Model Context Protocol (MCP) to expose its capabilities as a standardized JSON schema.  
* **Headless Server Configuration:** Use the openclaw-mcp integration to bridge the internal OpenClaw Gateway to external agents. This requires configuring environment variables such as OPENCLAW\_BASE\_URL (local Gateway URL), OPENCLAW\_GATEWAY\_TOKEN (bearer token for auth), and OPENCLAW\_AGENT\_ID.  
* **Security & Governance:** Never expose the MCP server to the open internet without a rigorous authentication proxy (like Tailscale or an Nginx Reverse Proxy with Basic Auth).  
* **Human-in-the-Loop (HITL):** Enforce strict "ask first" execution tiers. The AI can synthesize BANT qualifications and draft maintenance schedules, but autonomously dispatching trade workers or generating binding N4/N12 eviction notices requires a human manager's explicit "Approve" command.  
* **Mitigating Policy Drift:** Version-control agent permissions alongside capabilities and routinely execute deep security audits to ensure new MCP tools do not inadvertently expand the attack surface.

#### **6.2. Infrastructure Execution (Render Deployment)**

* **Persistent Storage Necessity:** Ephemeral filesystems on Render's Free tier will erase WhatsApp credentials and API keys upon every redeploy. You must use a Starter plan (or higher) to provision persistent block storage.  
* **Blueprint Configuration (render.yaml):**  
  * Define a persistent disk named openclaw-data and set its mountPath to /data.  
  * Configure the OPENCLAW\_STATE\_DIR to /data/.openclaw to persist credentials.  
  * Configure the OPENCLAW\_WORKSPACE\_DIR to /data/workspace to save generated PDFs and custom skills.  
* **Configuration Guardrails:** Maintain a "golden" backup (openclaw.json.golden) on the persistent disk. Implement a custom startup script in the Docker entrypoint to automatically restore this config if crucial channel bindings are corrupted by agent shell access.

#### **6.3. Omnichannel Telecommunications**

* **GoDaddy Email (IMAP/SMTP):**  
  * Integrate via the imap-smtp-email skill.  
  * **Crucial Step:** Administrators must explicitly toggle "SMTP Authentication" on in the GoDaddy Advanced Settings and generate an "App Password" to bypass MFA restrictions.  
  * **Settings:** Use imap.secureserver.net (Port 993, SSL/TLS) for polling tenant maintenance requests and smtpout.secureserver.net (Port 465, SSL/TLS) for outbound dispatches. Update DNS with SPF/DKIM records to avoid spam folders.  
* **WhatsApp (WebSockets):**  
  * Link a physical number by running openclaw channels login \--channel whatsapp in the Render shell and scanning the generated QR code.  
  * **Access Control:** To ensure the bot only responds to the 9-person ownership team, configure the dmPolicy to "allowlist" and populate the allowFrom array strictly with their E.164 formatted phone numbers.  
* **SMS & Voice (Twilio):**  
  * Twilio is recommended over SignalWire due to robust, community-vetted plugins.  
  * Install the @ranacseruet/clawphone Node.js HTTP gateway to bridge Twilio calls/SMS using plain TwiML webhooks (avoiding complex WebRTC setups).  
  * Implement the Agent-to-Human (A2H) protocol for high-risk operations: the agent pauses, sends an out-of-band AUTHORIZE request via SMS, and requires biometric authentication from a manager to proceed.

#### **6.4. Autonomous Workflows & State Management**

* **Cron vs. Heartbeat:**  
  * **HEARTBEAT.md:** Use for casual, low-priority polling (e.g., checking email every 30 minutes). It is prone to execution drift and should not be used for exact-time triggers.  
  * **Cron Scheduling:** Use for precise execution, such as the 4-month lease anniversary check.  
* **Cron Configuration:** Register recurring jobs with \--session isolated (to avoid polluting main chats), \--model opus (for complex rent calculation logic), and \--announce (to push the final brief directly to the ownership team).

#### **6.5. Document Automation (LTB Form Compliance)**

* **Programmatic Mapping:** AI models struggle with precise spatial layout. Instead of having the LLM generate a PDF, author a custom Python skill utilizing the pypdf library.  
* **Execution Flow:** The AI extracts property and tenant data from Supabase and passes it to the Python script. The script uses PdfReader.get\_form\_text\_fields() to map data to the exact programmatic text boxes on official, blank N4/N9/N12 templates.  
* **Storage:** The filled PdfWriter output is saved to the persistent /data/workspace directory for manager review.

#### **6.6. Database Architecture (Supabase Multi-Tenancy)**

* **Relational Schema:** Build four core tables—Properties, Tenant, Interactions, and Maintenance.  
* **The Tenant ID Identifier:** Every table must include a tenant\_id column representing the SaaS client (brokerage) to enable shared-database multi-tenancy.  
* **Row Level Security (RLS):**  
  * Enable RLS on all tables to ensure cryptographic data isolation.  
  * Inject the specific tenant\_id into the user's app\_metadata via a Supabase Auth Hook upon account creation.  
  * Create policies that append implicit WHERE clauses to every query (e.g., USING (tenant\_id \= (auth.jwt() \-\> 'app\_metadata' \-\>\> 'tenant\_id')::uuid)).  
* **Indexing:** Create a composite index on (tenant\_id, property\_id) across all tables to prevent catastrophic performance degradation during RLS filtering.

