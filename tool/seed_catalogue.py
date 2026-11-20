#!/usr/bin/env python3
"""Write the versioned catalogue JSON. The JSON files are the source of truth."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CANDIDATES = ROOT / "assets" / "data" / "candidates"
PUBLICATIONS = ROOT / "assets" / "data" / "publications"
REVIEWED = "2026-11-19"


def publication(
    pid,
    title,
    authors,
    year,
    ptype,
    *,
    venue=None,
    volume=None,
    issue=None,
    pages=None,
    notes,
    relevance,
):
    return {
        "id": pid,
        "title": title,
        "authors": authors,
        "year": year,
        "venue": venue,
        "volume": volume,
        "issue": issue,
        "pages": pages,
        "doi": None,
        "url": None,
        "abstract": None,
        "publicationType": ptype,
        "datasetOrArtifact": None,
        "verificationStatus": "unverified",
        "verificationNotes": notes,
        "relevanceNote": relevance,
        "accessDate": None,
    }


def node(
    cid,
    nid,
    stage,
    title,
    summary,
    detail,
    parent,
    children,
    *,
    status="unverified",
    sort=0,
    gap=None,
    links=None,
    tags=None,
    notes=None,
    assumptions=None,
    risks=None,
    validation=None,
):
    return {
        "id": nid,
        "candidateId": cid,
        "stage": stage,
        "title": title,
        "summary": summary,
        "detail": detail,
        "parentId": parent,
        "childIds": children,
        "evidenceStatus": status,
        "evidenceLinkIds": links or [],
        "relatedNodeIds": [],
        "tags": tags or [],
        "sortOrder": sort,
        "notes": notes or [],
        "assumptions": assumptions or [],
        "risks": risks or [],
        "validationRequirements": validation or [],
        "gapStrength": gap,
        "lastReviewed": REVIEWED,
    }


def link(lid, node_id, pub, relationship, claim, limitation, strength="indirect"):
    return {
        "id": lid,
        "nodeId": node_id,
        "publicationId": pub,
        "relationship": relationship,
        "claim": claim,
        "limitation": limitation,
        "evidenceStrength": strength,
        "verificationStatus": "unverified",
        "pageOrSection": None,
        "notes": "Bibliographic record and the paper's actual findings still need to be checked.",
        "confidence": "low",
    }


def candidate_doc(candidate, nodes, links, crosses=None):
    return {
        "schemaVersion": "1.0.0",
        "candidate": candidate,
        "nodes": nodes,
        "evidenceLinks": links,
        "crossLinks": crosses or [],
    }


def dump(path, payload):
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def readiness(items):
    labels = {
        "bounded": "Bounded problem and one primary question",
        "contribution": "Defensible technical contribution",
        "literature": "Literature map with supporting and contradictory studies",
        "fulltext": "Directly relevant full-text-checked publications",
        "resources": "Datasets, tools, or practitioner access documented",
        "design": "Feasible experimental design and measurable criteria",
        "mphil": "Appropriate for an MPhil in Information Technology",
    }
    return [
        {"id": key, "label": labels[key], "met": met, "note": note}
        for key, met, note in items
    ]


# --- publications -----------------------------------------------------------

kente_pubs = [
    publication(
        "pub-badoe-2005",
        "Analytical Study of the Structural Patterns of Asante Kente",
        ["Badoe, F."],
        2005,
        "other",
        notes="Year and author form are taken from project notes. Venue, DOI, and publication type are not confirmed.",
        relevance="Cited as documentation of structural patterns in Asante Kente, not as a computational specification.",
    ),
    publication(
        "pub-badoe-opoku-asare",
        "Structural Patterns in Asante Kente: An Indigenous Instructional Resource for Design Education in Textiles",
        ["Badoe, F.", "Opoku-Asare, N. A."],
        None,
        "other",
        notes="Title is taken from project notes. Year, venue, and DOI must be verified from the original record.",
        relevance="Useful knowledge base for structural patterns. It does not, by itself, establish a machine-readable specification or a generation algorithm.",
    ),
    publication(
        "pub-ahteck-2024",
        "Ahteck et al. (2024), textile or weaving-related computational or design research",
        ["Ahteck et al."],
        2024,
        "other",
        notes="Author shorthand and year come from discussion notes. Exact title, venue, and relevance are unverified.",
        relevance="A literature lead for computational textile or weaving research. Not yet evidence for a Kente-specific gap.",
    ),
    publication(
        "pub-ulos-2024",
        "Ulos-related computational textile work (2024)",
        [],
        2024,
        "other",
        notes="Exact publication and scope are still to be verified. This is a search lead, not a completed citation.",
        relevance="May inform computational treatment of another textile tradition. Relevance to Asante Kente must be checked.",
    ),
    publication(
        "pub-bamboo-2025",
        "Bamboo-weaving computational or design research (2025)",
        [],
        2025,
        "other",
        notes="Exact publication and scope are still to be verified.",
        relevance="A lead on computational weaving outside Kente. Do not treat it as Kente evidence.",
    ),
    publication(
        "pub-kirgiz-2026",
        "Kirgiz weaving research (2026)",
        [],
        2026,
        "other",
        notes="Exact publication and scope are still to be verified.",
        relevance="A lead on another weaving tradition. Scope relative to Kente is unknown.",
    ),
    publication(
        "pub-tang-2026",
        "FabricGen / WeavingLLM (Tang et al., 2026)",
        ["Tang et al."],
        2026,
        "other",
        notes="Reported as FabricGen/WeavingLLM. Exact title, venue, publication type, and whether the work addresses physical constraints are unverified.",
        relevance="A lead on textile generation. It is not yet known whether it evaluates loom-level validity.",
    ),
    publication(
        "pub-boonyaputthipong-2026",
        "Ikat co-design (Boonyaputthipong et al., 2026)",
        ["Boonyaputthipong et al."],
        2026,
        "other",
        notes="Exact title, venue, and technical contribution are unverified.",
        relevance="A lead on textile co-design and evaluation. Metrics and prototypes still need to be extracted.",
    ),
    publication(
        "pub-wang-2026",
        "Shape grammar work (Wang et al., 2026)",
        ["Wang et al."],
        2026,
        "other",
        notes="Exact publication is unverified, including whether it addresses textile structure.",
        relevance="A possible methodological precedent for grammar-based pattern structure.",
    ),
    publication(
        "pub-sawyerr-2026",
        "Ghanaian textile AI (Sawyerr et al., 2026)",
        ["Sawyerr et al."],
        2026,
        "other",
        notes="Exact publication and relevance are unverified.",
        relevance="A lead that may concern Ghanaian textiles. It is not yet known whether it models weave structure.",
    ),
    publication(
        "pub-weavedraft",
        "weaveDraft",
        [],
        None,
        "software_or_artifact",
        notes="Recorded as a tool or system. No research publication has been identified, so this must not be presented as a peer-reviewed paper.",
        relevance="A possible source of machine-readable weave structures. Loom assumptions are unknown.",
    ),
]

crop_pubs = [
    publication(
        "pub-ye-2026",
        "Description-Guided CLIP (Ye et al., 2026)",
        ["Ye et al."],
        2026,
        "other",
        notes="Reported as Description-Guided CLIP. Exact title, venue, datasets, and split design are unverified.",
        relevance="A lead on crop-disease recognition and generalisation. Not proof of the proposed gap.",
    ),
    publication(
        "pub-xiong-2026",
        "BLAP (Xiong et al., 2026)",
        ["Xiong et al."],
        2026,
        "other",
        notes="Full title and the exact problem addressed are unverified.",
        relevance="A discovery lead for crop-disease recognition. Methods and datasets must be checked.",
    ),
    publication(
        "pub-kang-2026",
        "Leakage or session splits (Kang, 2026)",
        ["Kang"],
        2026,
        "other",
        notes="Bibliographic details are unverified, including whether the work studies agricultural image datasets.",
        relevance="A lead on leakage-aware or session-aware splits. The empirical effect size is not yet extracted.",
    ),
    publication(
        "pub-mooraj-2026",
        "AgriPath-LF16 (Mooraj et al., 2026)",
        ["Mooraj et al."],
        2026,
        "other",
        notes="Dataset or task details, publication type, and relevance are unverified.",
        relevance="A possible field-oriented dataset lead. Composition and split design are unknown.",
    ),
    publication(
        "pub-ccmt",
        "CCMT crop-disease image dataset",
        [],
        None,
        "dataset",
        notes="Discussed as containing 24,881 original images. Version, composition, licensing, and contamination characteristics must be confirmed from source documentation. The image count is not treated as verified.",
        relevance="A candidate public dataset for a leakage and domain-shift protocol. Provenance is not yet audited.",
    ),
]

adaptive_pubs = []

se_pubs = [
    publication(
        "pub-ali-2022",
        "Software effort estimation accuracy prediction of machine learning techniques: A systematic performance evaluation",
        ["Ali, A."],
        2022,
        "journal_article",
        venue="Software: Practice and Experience",
        volume="52",
        issue="1",
        pages="39-65",
        notes="Citation details are taken from the project's Scopus notes and are still marked unverified against the publisher record.",
        relevance="A systematic performance evaluation of machine-learning effort estimation. Dataset and validation choices need to be extracted.",
    ),
    publication(
        "pub-pospieszny-2018",
        "An effective approach for software project effort and duration estimation with machine learning algorithms",
        ["Pospieszny, P.", "Czarnacka-Chrobot, B.", "Kobyliński, A."],
        2018,
        "journal_article",
        venue="Journal of Systems and Software",
        volume="137",
        pages="184-196",
        notes="Citation details are from Scopus notes and remain unverified against the publisher record.",
        relevance="An empirical machine-learning effort and duration study. Split strategy is not yet extracted.",
    ),
    publication(
        "pub-sousa-2023",
        "Applying machine learning to estimate the effort and duration of individual tasks in software projects",
        ["Sousa et al."],
        2023,
        "journal_article",
        venue="IEEE Access",
        volume="11",
        pages="89933-89946",
        notes="Author list is incomplete in the project notes. Venue, volume, and pages are from those notes and are unverified.",
        relevance="Directly relevant to task-level, rather than only project-level, estimation.",
    ),
    publication(
        "pub-mahdi-2021",
        "Software project management using machine learning technique—a review",
        ["Mahdi et al."],
        2021,
        "journal_article",
        venue="Applied Sciences",
        volume="11",
        issue="11",
        notes="Author list is incomplete in the project notes. The citation remains unverified.",
        relevance="A review lead. It may already cover parts of the proposed methodological gap.",
    ),
    publication(
        "pub-behdinian-2022",
        "An integrating machine learning algorithm and simulation method for improving software project management: A case study",
        ["Behdinian et al."],
        2022,
        "journal_article",
        venue="Journal of Quality Engineering and Production Optimization",
        volume="7",
        issue="1",
        pages="54-74",
        notes="Author list is incomplete. Citation details are from Scopus notes and remain unverified.",
        relevance="Combines machine learning and simulation in a case study. Generalisation beyond the case is unknown.",
    ),
    publication(
        "pub-rahman-2023",
        "Software effort estimation using machine learning technique",
        ["Rahman et al."],
        2023,
        "journal_article",
        venue="International Journal of Advanced Computer Science and Applications",
        volume="14",
        issue="4",
        notes="Author list is incomplete. Citation details remain unverified.",
        relevance="Another machine-learning estimation study. Protocol differences are the point of interest, not a new bake-off.",
    ),
    publication(
        "pub-raman-2024",
        "Optimizing software effort estimation accuracy with a machine learning model",
        ["Raman et al."],
        2024,
        "conference_paper",
        venue="INCET 2024",
        notes="Author list and proceedings details are incomplete and unverified.",
        relevance="A recent accuracy-optimisation study. Baselines and datasets are not yet extracted.",
    ),
    publication(
        "pub-rajput-2025",
        "Comparative analysis of machine-learning techniques for software effort estimation",
        ["Rajput", "Razi", "Sharma"],
        2025,
        "conference_paper",
        venue="CICTN 2025",
        notes="Title is paraphrased from project notes, not copied from a verified record. Venue shorthand is unverified.",
        relevance="A comparative analysis lead. It is not yet known whether validation leakage is discussed.",
    ),
    publication(
        "pub-chakravorty-2025",
        "Enhancing effort and estimation in scrum-based agile projects with a proposed federated agile framework",
        ["Chakravorty", "Reddy", "Khan"],
        2025,
        "journal_article",
        venue="International Journal of Information Technology",
        notes="Full bibliographic record must be verified. Author given names are not in the project notes.",
        relevance="A lead on agile, possibly task-level, estimation. The technical contribution is unverified.",
    ),
]

language_pubs = []
context_pubs = []


def spine(cid, short, problem, question, relevance, outcomes, areas):
    """Build a valid hierarchy. areas is a list of dicts with keys name, status, gap, topic, questions."""
    nodes = []
    links = []
    outcome_ids = [f"{cid}-outcome-{i}" for i in range(len(outcomes))]
    area_ids = [f"{cid}-area-{i}" for i in range(len(areas))]
    rel_children = [f"{cid}-relevance-ghana", f"{cid}-relevance-computing", f"{cid}-relevance-contribution"]
    nodes.append(
        node(
            cid,
            f"{cid}-problem",
            "thesis_problem",
            problem["title"],
            problem["summary"],
            problem["detail"],
            None,
            [f"{cid}-question"],
            status=problem.get("status", "hypothesis"),
            assumptions=problem.get("assumptions", []),
            risks=problem.get("risks", []),
        )
    )
    nodes.append(
        node(
            cid,
            f"{cid}-question",
            "thesis_question",
            question["title"],
            question["summary"],
            question["detail"],
            f"{cid}-problem",
            [f"{cid}-relevance", *outcome_ids, *area_ids],
            status="hypothesis",
        )
    )
    nodes.append(
        node(
            cid,
            f"{cid}-relevance",
            "relevance",
            relevance["title"],
            relevance["summary"],
            relevance["detail"],
            f"{cid}-question",
            rel_children,
            sort=0,
            status="hypothesis",
        )
    )
    for index, (nid, title, detail) in enumerate(
        [
            (rel_children[0], relevance["ghana_title"], relevance["ghana"]),
            (rel_children[1], relevance["computing_title"], relevance["computing"]),
            (rel_children[2], relevance["contribution_title"], relevance["contribution"]),
        ]
    ):
        nodes.append(
            node(
                cid,
                nid,
                "relevance",
                title,
                title,
                detail,
                f"{cid}-relevance",
                [],
                sort=index,
                status="hypothesis",
            )
        )
    for index, (title, detail) in enumerate(outcomes):
        nodes.append(
            node(
                cid,
                outcome_ids[index],
                "expected_outcomes",
                title,
                title,
                detail,
                f"{cid}-question",
                [],
                sort=index,
                status="hypothesis",
            )
        )
    for index, area in enumerate(areas):
        aid = area_ids[index]
        sid = f"{cid}-status-{index}"
        gid = f"{cid}-gap-{index}"
        tid = f"{cid}-topic-{index}"
        qids = [f"{cid}-rq-{index}-{q}" for q in range(len(area["questions"]))]
        nodes.append(
            node(
                cid,
                aid,
                "thesis_areas",
                area["name"],
                area["name"],
                area["detail"],
                f"{cid}-question",
                [sid],
                sort=index,
                status="hypothesis",
            )
        )
        nodes.append(
            node(
                cid,
                sid,
                "current_status_quo",
                area["status_title"],
                area["status_title"],
                area["status"],
                aid,
                [gid],
                status=area.get("status_evidence", "needs_literature"),
                notes=area.get("status_notes", []),
            )
        )
        nodes.append(
            node(
                cid,
                gid,
                "literature_gaps",
                area["gap_title"],
                area["gap_title"],
                area["gap"],
                sid,
                [tid],
                status=area.get("gap_status", "hypothesis"),
                gap=area.get("gap_strength", "unconfirmed"),
                links=[item["id"] for item in area.get("evidence", [])],
                risks=area.get("risks", []),
                validation=area.get("validation", []),
            )
        )
        nodes.append(
            node(
                cid,
                tid,
                "potential_topics",
                area["topic"],
                area["topic"],
                area.get("topic_detail", area["topic"]),
                gid,
                qids,
                status="hypothesis",
                tags=area.get("topic_tags", []),
            )
        )
        for qindex, question_text in enumerate(area["questions"]):
            nodes.append(
                node(
                    cid,
                    qids[qindex],
                    "research_questions",
                    question_text,
                    question_text,
                    question_text,
                    tid,
                    [],
                    sort=qindex,
                    status="hypothesis",
                )
            )
        for item in area.get("evidence", []):
            links.append(item)
    return nodes, links


# --- Kente ------------------------------------------------------------------

kente_evidence = {
    0: [
        link(
            "ev-kente-0-tang",
            "kente-gap-0",
            "pub-tang-2026",
            "supports_context",
            "Project notes describe Tang et al. (2026) as FabricGen/WeavingLLM, a textile-generation lead.",
            "The notes do not establish whether the work represents physical or loom-level constraints.",
            "uncertain",
        ),
        link(
            "ev-kente-0-wang",
            "kente-gap-0",
            "pub-wang-2026",
            "methodological_precedent",
            "Project notes describe Wang et al. (2026) as shape-grammar work that might bear on pattern structure.",
            "It is not yet known whether the work addresses textile structure.",
            "uncertain",
        ),
    ],
    1: [
        link(
            "ev-kente-1-badoe",
            "kente-gap-1",
            "pub-badoe-2005",
            "supports_context",
            "Badoe (2005) is cited in the project notes as an analytical study of Asante Kente structural patterns.",
            "The notes do not establish a machine-readable specification or a generation algorithm.",
            "contextual",
        ),
        link(
            "ev-kente-1-badoe-opoku",
            "kente-gap-1",
            "pub-badoe-opoku-asare",
            "supports_context",
            "Badoe and Opoku-Asare are cited as documenting structural patterns for textile design education.",
            "Educational documentation is not the same as a computational model of loom execution.",
            "contextual",
        ),
        link(
            "ev-kente-1-sawyerr",
            "kente-gap-1",
            "pub-sawyerr-2026",
            "supports_context",
            "Sawyerr et al. (2026) is a lead on Ghanaian textile AI.",
            "Relevance to weave structure, rather than visual generation, is unverified.",
            "uncertain",
        ),
    ],
    2: [
        link(
            "ev-kente-2-ikat",
            "kente-gap-2",
            "pub-boonyaputthipong-2026",
            "supports_context",
            "Boonyaputthipong et al. (2026) is a lead on Ikat co-design and therefore on how textile outputs are judged.",
            "Evaluation metrics, expert involvement, and physical checks have not been extracted.",
            "uncertain",
        )
    ],
    3: [
        link(
            "ev-kente-3-draft",
            "kente-gap-3",
            "pub-weavedraft",
            "tool_or_artifact",
            "weaveDraft is recorded as a software tool that may expose weave information.",
            "No research paper has been identified, and its loom assumptions are unknown.",
            "uncertain",
        )
    ],
}

kente_areas = [
    {
        "name": "Computational textile generation",
        "detail": "Methods that generate textile patterns, including recent learning-based and grammar-based leads.",
        "status_title": "Generation methods may optimise appearance",
        "status": "The leads gathered so far, including reported FabricGen/WeavingLLM and shape-grammar work, suggest that computational textile generation is an active area. Whether those systems encode a specific weaving process is not established by the notes.",
        "status_evidence": "needs_literature",
        "gap_title": "Visual plausibility may be produced without a specific weaving process",
        "gap": "The reviewed leads do not yet establish whether current textile-generation methods represent the structural constraints of a specified weaving process, or mainly the look of a finished cloth. This is a hypothesis until the Scopus records and full texts are checked.",
        "gap_status": "hypothesis",
        "topic": "Compare unconstrained and constraint-aware generation for a bounded pattern class",
        "questions": [
            "Which structural constraints determine whether a generated pattern is feasible within the selected scope?",
            "How do generated patterns compare with baseline methods on structural validity, diversity, and instruction completeness?",
        ],
        "evidence": kente_evidence[0],
        "validation": ["Define validity checks before comparing visual similarity."],
    },
    {
        "name": "Kente structure versus other textile traditions",
        "detail": "What is known specifically about Asante Kente structure, as distinct from other weaving traditions and from broadloom translation.",
        "status_title": "Structural patterns are documented for design education",
        "status": "Badoe, and Badoe and Opoku-Asare, are treated as documentation of structural patterns and their use in textile design education. Studies of Ulos, Ikat, Kirgiz weaving, and bamboo weaving are separate traditions and cannot be assumed to describe Kente.",
        "status_evidence": "unverified",
        "gap_title": "General textile models may not capture Asante Kente conventions",
        "gap": "Within the sources identified so far, documentation of Kente structure has not been shown to amount to a bounded, machine-readable representation of selected weave structures. Other textile studies remain contextual until their scope is checked.",
        "topic": "A bounded, Kente-specific structural representation",
        "questions": [
            "How can selected Asante Kente motifs and weaving structures be represented in a machine-readable form?",
        ],
        "evidence": kente_evidence[1],
        "risks": ["Do not model all Kente traditions. Select a bounded set of structures."],
    },
    {
        "name": "Evaluation of structural validity",
        "detail": "How generated textiles are judged: visual similarity, preference, structural checks, or executable instructions.",
        "status_title": "Evaluation criteria in the leads are not yet extracted",
        "status": "The project notes flag that evaluation may emphasise visual similarity or preference. The metrics, expert protocols, and prototypes used in the identified leads have not been extracted.",
        "status_evidence": "needs_literature",
        "gap_title": "Evaluation may not measure structural validity or weave compatibility",
        "gap": "It is not yet known whether the studies reviewed so far measure structural validity or practical weave compatibility, rather than image similarity or preference alone. The gap stays unconfirmed until those evaluations are read.",
        "topic": "A multi-part evaluation protocol for constraint satisfaction",
        "questions": [
            "How should structural validity, constraint satisfaction, diversity, and expert judgement be reported together?",
        ],
        "evidence": kente_evidence[2],
        "validation": [
            "Do not claim physical weaveability from image-level metrics.",
            "Expert review and physical samples are desirable only if access is feasible.",
        ],
    },
    {
        "name": "From a pattern file to a weaving specification",
        "detail": "The difference between a drawing of a cloth and instructions a specified loom could follow.",
        "status_title": "Tools and papers may stop at the drawing",
        "status": "A two-dimensional pattern grid may not capture supplementary wefts, floats, layers, or loom-specific constraints. weaveDraft is a tool lead, not a verified research result. A draft shown on a broadloom should not be assumed executable on a traditional narrow loom.",
        "status_evidence": "hypothesis",
        "gap_title": "A digital pattern may not be an executable weaving specification",
        "gap": "The identified leads do not yet show a representation that links visible Kente design, weave structure, and loom execution for a specified loom. 'Loom-compatible' is not self-defining and must be narrowed before it is claimed.",
        "topic": "Constrain the claim to a specified loom context, or drop production language",
        "questions": [
            "Which loom type, structural rules, and output checks define a valid result in this thesis?",
            "To what extent do domain experts judge the generated instructions to be faithful to the selected practice?",
        ],
        "evidence": kente_evidence[3],
        "risks": [
            "If loom specifications or knowledgeable reviewers are not available, narrow the claim to structurally constrained pattern generation.",
        ],
    },
]

kente_nodes, kente_links = spine(
    "kente",
    "Kente",
    {
        "title": "Plausible textile images are not necessarily weavable structures",
        "summary": "Digital pattern tools can look convincing without representing the weave and loom constraints that decide whether a cloth can be made.",
        "detail": "Existing digital pattern generation can create visually plausible textile designs without necessarily representing the underlying weave structures and loom-specific constraints that determine whether a design can actually be woven. The candidate is limited to selected Asante Kente structures and one specified loom context.",
        "assumptions": [
            "A bounded set of structures is enough for an MPhil contribution.",
            "Image similarity is not evidence of weaveability.",
        ],
        "risks": [
            "Access to weave-structure information or experienced reviewers may not be available in the research period.",
        ],
    },
    {
        "title": "How can selected Kente structures be generated under weaving constraints?",
        "summary": "How can selected Asante Kente weaving structures be represented computationally and used to generate novel patterns that satisfy defined weaving constraints?",
        "detail": "The central question is how selected Asante Kente weaving structures can be represented computationally and used to generate novel patterns that satisfy defined weaving constraints. It is not a question about generating attractive textile images in general.",
    },
    {
        "title": "Why this is a computing problem",
        "summary": "The contribution has to be a representation, a constraint model, and an evaluation, not only a description of Kente.",
        "detail": "The candidate stays inside information technology only if the output is a computational representation and a checkable generation method.",
        "ghana_title": "Grounded in Asante weaving practice",
        "ghana": "The direction is grounded in Ghanaian textile practice. That relevance does not by itself make the work a computing contribution, and it does not license claims about all Kente traditions.",
        "computing_title": "A representation and a constraint check",
        "computing": "The technical object is a layered representation: design, weave structure, loom execution, and constraint validation. A traditional narrow-loom practice and a broadloom translation must not be collapsed into one claim.",
        "contribution_title": "What would count as a contribution",
        "contribution": "A layered computational representation of selected designs, a formalised constraint set for a bounded pattern class, a generator that rejects or repairs invalid outputs, and an evaluation of structural validity and execution feasibility rather than image similarity alone.",
    },
    [
        (
            "Structured representation of selected motifs",
            "A machine-readable account of selected motifs and weaving structures, not a general catalogue of Kente.",
        ),
        (
            "Formal constraint model",
            "Structural and loom-specific rules explicit enough to accept or reject a candidate pattern.",
        ),
        (
            "Generation method",
            "An algorithm or prototype that proposes patterns and rejects or repairs structurally invalid outputs.",
        ),
        (
            "Machine-checkable validation",
            "A procedure that reports validity, diversity, and constraint satisfaction without treating visual similarity as weaveability.",
        ),
        (
            "External check, only if feasible",
            "Assessment by experienced weavers and, where feasible, physical weaving of a small number of samples. Feasibility has to be settled early.",
        ),
    ],
    kente_areas,
)

kente_candidate = {
    "id": "kente",
    "title": "Constraint-Aware Computational Generation of Loom-Compatible Asante Kente Patterns",
    "shortTitle": "Kente generation",
    "workingTitle": "Constraint-Aware Computational Generation of Loom-Compatible Asante Kente Patterns",
    "summary": "Can selected Asante Kente structures be represented so that a generator respects weaving constraints, not only the look of the cloth?",
    "shortDescription": "Investigates computational generation of Kente patterns under explicit structural and loom-related constraints.",
    "priority": "primary",
    "status": "promising",
    "ghanaianRelevance": "Directly grounded in Ghanaian textile practice. The scope must stay on selected structures rather than all Kente traditions.",
    "technicalContribution": "A constraint-aware representation and generation or evaluation pipeline for structurally valid patterns within a specified loom context.",
    "feasibility": {
        "rating": "medium",
        "rationale": "This is a planning assessment. Feasibility depends on reliable weave-structure information and a testable definition of loom compatibility.",
    },
    "dataRequirements": "A bounded set of documented Kente structures, an explicit loom context, and access to the papers behind the current leads. Weaver review is optional and must be confirmed early.",
    "evaluationDesign": "Compare constraint-aware and unconstrained generation on structural validity, constraint satisfaction, diversity, and completeness of instructions. Do not use image similarity as a substitute for weaveability.",
    "majorRisks": [
        "Loom compatibility is undefined until the loom and the structural rules are specified.",
        "Several 2024–2026 leads have incomplete bibliographic metadata.",
    ],
    "rootNodeId": "kente-problem",
    "tags": ["computational-design", "textiles", "constraints", "ghana"],
    "openDecisions": [
        "Which bounded set of structures and which loom context define a valid output?",
        "If practitioner access is not feasible, should the claim drop production-ready loom execution?",
    ],
    "readiness": readiness(
        [
            ("bounded", False, "The problem is clear, but the loom and structure bounds are still open."),
            ("contribution", True, "The intended contribution is a representation, a constraint model, and an evaluation."),
            ("literature", False, "Leads are recorded, but full texts and contradictory studies are not yet reviewed."),
            ("fulltext", False, "No publication in this catalogue is marked full-text checked."),
            ("resources", True, "The dependency on weave documentation and optional expert access is written down."),
            ("design", True, "A comparison of constrained and unconstrained generation is sketched."),
            ("mphil", True, "The contribution is computational if the scope stays on representation and validation."),
        ]
    ),
    "lastReviewed": REVIEWED,
}


crop_areas = [
    {
        "name": "Field images versus curated test sets",
        "detail": "Whether reported accuracy on curated crop-disease images holds when the camera, place, lighting, or background changes.",
        "status_title": "High curated accuracy is a weak deployment claim",
        "status": "Crop-disease image classification is already a crowded area. A generic classifier is unlikely to be a contribution. Curated datasets and random image-level splits may not represent field conditions. Ye et al. (2026), Xiong et al. (2026), and AgriPath-LF16 are leads, not demonstrations of the gap.",
        "status_evidence": "needs_literature",
        "gap_title": "Reported test scores may not survive a change of field conditions",
        "gap": "The leads do not yet establish how much performance changes when training and test images differ in background, device, location, or lighting. The gap is a hypothesis until split design and field-versus-controlled conditions are extracted from the papers.",
        "topic": "Measure degradation under documented field shifts",
        "questions": [
            "How does performance, calibration, and uncertainty change under a clearly documented field shift?",
        ],
        "evidence": [
            link(
                "ev-crop-0-ye",
                "crop-gap-0",
                "pub-ye-2026",
                "supports_context",
                "Ye et al. (2026) is noted as Description-Guided CLIP, a lead on crop-disease recognition and generalisation.",
                "Dataset composition and whether domain shift was measured are unverified.",
                "uncertain",
            ),
            link(
                "ev-crop-0-mooraj",
                "crop-gap-0",
                "pub-mooraj-2026",
                "dataset_or_benchmark",
                "AgriPath-LF16 is noted as a possible field-oriented dataset or task.",
                "Composition and split design are unverified.",
                "uncertain",
            ),
        ],
        "risks": ["Do not expand this into explainability, fairness, compression, and diagnosis at once."],
    },
    {
        "name": "Leakage and correlated splits",
        "detail": "Near-duplicate images, capture sessions, or the same plant appearing on both sides of a split.",
        "status_title": "Random image splits can leak near-duplicates",
        "status": "Project notes point to Kang (2026) on leakage or session splits, and to the CCMT dataset as a public corpus whose contamination is not yet audited. Neither the paper's effect size nor the dataset's duplicate structure has been verified.",
        "status_evidence": "needs_literature",
        "gap_title": "Random splits may overstate generalisation when images are correlated",
        "gap": "It is not yet measured, in the sources reviewed here, how much reported performance changes when correlated images or acquisition sessions are kept out of both sides of a split. This remains a hypothesis.",
        "topic": "Compare random image splits with session-aware splits",
        "questions": [
            "How does leakage-aware splitting change the measured performance of selected crop-disease models?",
        ],
        "evidence": [
            link(
                "ev-crop-1-kang",
                "crop-gap-1",
                "pub-kang-2026",
                "methodological_precedent",
                "Kang (2026) is a lead on leakage or session splits.",
                "It is unverified whether the paper studies agricultural images, and the effect size is unknown.",
                "uncertain",
            ),
            link(
                "ev-crop-1-ccmt",
                "crop-gap-1",
                "pub-ccmt",
                "dataset_or_benchmark",
                "CCMT was discussed as a public crop-disease image collection of about 24,881 images.",
                "The count, version, class map, licence, and known duplicates are not confirmed from source documentation.",
                "uncertain",
            ),
        ],
        "validation": ["Publish the split protocol and the dataset version actually used."],
    },
    {
        "name": "Confidence under shift",
        "detail": "Whether accuracy hides overconfident or poorly calibrated predictions when the field distribution changes.",
        "status_title": "Accuracy does not describe confidence",
        "status": "The notes argue that models may be overconfident on unfamiliar field images. Calibration and selective-prediction studies in the Scopus export have not yet been extracted, so this status is a prompt for reading, not a finding.",
        "status_evidence": "needs_literature",
        "gap_title": "Accuracy can hide unsafe confidence under distribution shift",
        "gap": "The sources identified so far have not been shown to evaluate calibration under field shift, as opposed to in-domain test sets. Whether selective prediction can reject unreliable crop-disease predictions at a useful coverage is an open question.",
        "topic": "Calibration and selective prediction under the same shifts",
        "questions": [
            "To what extent do contamination and field shift affect confidence calibration?",
            "Can selective prediction reduce high-confidence errors while keeping useful coverage?",
        ],
        "evidence": [
            link(
                "ev-crop-2-xiong",
                "crop-gap-2",
                "pub-xiong-2026",
                "supports_context",
                "Xiong et al. (2026), reported as BLAP, is a discovery lead in this area.",
                "The problem the paper actually addresses is unverified, so it is not evidence of a calibration gap.",
                "uncertain",
            )
        ],
    },
    {
        "name": "What kind of model is being evaluated",
        "detail": "Conventional image classifiers compared with vision-language approaches, only if the literature justifies it.",
        "status_title": "Another classifier bake-off is not the contribution",
        "status": "The contribution has to stay on reliability and evaluation. Few-shot or vision-language methods are in scope only if the literature gives a reason to include them.",
        "status_evidence": "hypothesis",
        "gap_title": "It is unknown whether vision-language models change the failure mode",
        "gap": "The notes do not establish whether few-shot or vision-language methods improve robustness here or only move the errors. That comparison is optional and secondary to the evaluation protocol.",
        "topic": "Hold the evaluation protocol fixed and vary the model family",
        "questions": [
            "Under one leakage-aware protocol, how do conventional classifiers compare with a selected vision-language approach?",
        ],
        "gap_status": "hypothesis",
        "evidence": [],
        "topic_tags": ["exploratory"],
    },
]

crop_nodes, crop_links = spine(
    "crop",
    "Crop",
    {
        "title": "Curated crop-disease accuracy may not be reliable in the field",
        "summary": "A strong score on a cleaned image set can hide leakage, poor calibration, and a drop when the photographs come from real fields.",
        "detail": "High classification performance on curated crop-disease datasets may not translate into reliable predictions on real field images. Duplication, leakage, or correlated capture sessions can inflate reported performance, and models may be overconfident on unfamiliar conditions. The contribution is an evaluation protocol, not another classifier.",
        "risks": [
            "If dataset provenance cannot be audited, the leakage claim cannot be tested.",
            "Ghana-specific field images are in scope only if access and annotation fit the research period.",
        ],
    },
    {
        "title": "How do contamination and field shift affect reliability, not just accuracy?",
        "summary": "How do dataset contamination and field-domain shift affect predictive reliability, confidence calibration, and selective prediction?",
        "detail": "The question is how dataset contamination and field-domain shift affect the predictive reliability, confidence calibration, and selective prediction performance of crop-disease recognition models.",
    },
    {
        "title": "Why reliability is the contribution",
        "summary": "The field already has many classifiers. The opening is in how performance is measured.",
        "detail": "A new architecture trained on a public dataset would not, by itself, make a sufficient MPhil contribution.",
        "ghana_title": "Local field images are optional",
        "ghana": "Public datasets are the default. Ghana-specific field photographs may be added only if collection and annotation are feasible. They are not required to state the problem.",
        "computing_title": "An evaluation protocol for vision models",
        "computing": "The technical work is a reproducible audit of splits, a measurement of accuracy and confidence under shift, and a comparison of calibration and selective-prediction methods.",
        "contribution_title": "What would count as a contribution",
        "contribution": "A reproducible protocol for leakage and correlated splits, a measurement of how contamination and shift change performance and confidence, a comparison of calibration and reject-option methods, and guidance that goes beyond accuracy.",
    },
    [
        ("An audited split protocol", "A written, repeatable way to detect or control image leakage and correlated splits."),
        ("A reproducible pipeline", "Code and fixed dataset versions so the comparison can be rerun."),
        ("Baseline results under both splits", "The same models scored with a conventional split and a leakage-aware split."),
        ("Calibration and selective prediction", "Confidence quality and risk-coverage, not accuracy alone."),
        ("Shift analysis", "How errors and confidence move when the field conditions change."),
        ("Evaluation guidance", "Recommendations that say what the measurements do and do not show."),
    ],
    crop_areas,
)

crop_candidate = {
    "id": "crop",
    "title": "Reliability of crop-disease AI under field-domain shift and data contamination",
    "shortTitle": "Crop-disease reliability",
    "workingTitle": "Evaluating the Impact of Dataset Contamination and Field-Domain Shift on the Reliability of AI-Based Crop-Disease Recognition",
    "summary": "How much of the reported accuracy of crop-disease models is an artefact of leakage or of a test set that does not look like the field?",
    "shortDescription": "An evaluation-centred study of leakage, field shift, calibration, and selective prediction.",
    "priority": "primary",
    "status": "promising",
    "ghanaianRelevance": "Field agriculture in Ghana is a possible setting, not a requirement. Public datasets are preferred unless local images can be collected properly.",
    "technicalContribution": "A leakage-aware evaluation protocol and evidence about calibration and selective prediction under field shift.",
    "feasibility": {
        "rating": "medium",
        "rationale": "This is a planning assessment. The work is measurable if a public dataset's provenance and split metadata can be audited.",
    },
    "dataRequirements": "One or two public crop-disease datasets with known versions, plus the papers needed to define leakage and shift. Local images only if annotation is feasible.",
    "evaluationDesign": "Hold models fixed where possible. Compare random image splits with group or session splits, then report accuracy, calibration, and selective prediction under a documented shift.",
    "majorRisks": [
        "CCMT's size and contamination are not verified.",
        "The 2026 leads may not study the mechanism this topic needs.",
    ],
    "rootNodeId": "crop-problem",
    "tags": ["computer-vision", "calibration", "dataset-leakage", "agriculture"],
    "openDecisions": [
        "Which single crop or disease domain and which public datasets bound the study?",
        "Is vision-language comparison justified, or does it dilute the evaluation contribution?",
    ],
    "readiness": readiness(
        [
            ("bounded", False, "The question is sharp, but the dataset and crop bound are not fixed."),
            ("contribution", True, "The contribution is an evaluation protocol rather than a new classifier."),
            ("literature", False, "Leads exist. Full texts, contradictory results, and effect sizes are not extracted."),
            ("fulltext", False, "No source is marked full-text checked."),
            ("resources", True, "Public data is the planned source, with local images treated as optional."),
            ("design", True, "The split comparison and the metrics are sketched."),
            ("mphil", True, "Reliability measurement is a computing contribution if the scope stays narrow."),
        ]
    ),
    "lastReviewed": REVIEWED,
}

adaptive_areas = [
    {
        "name": "Choosing the system that adapts",
        "detail": "Edge, fog, or mobile computing are areas, not yet a thesis problem. One system class has to be chosen.",
        "status_title": "The system boundary is not chosen",
        "status": "Resource-aware and adaptive systems are a large literature. No specific system class, workload, or adaptation variable has been fixed for this candidate, so there is no status quo to cite yet.",
        "status_evidence": "needs_literature",
        "gap_title": "A single-resource objective may ignore the rest of the trade-off",
        "gap": "It is plausible that some adaptive systems optimise one resource and under-report latency, energy, memory, and output quality together. That is not established here. The literature review has not been done.",
        "gap_status": "needs_literature",
        "topic": "One adaptation policy for one system class",
        "topic_detail": "Pick one system, one decision it can change, and one measurable quality target before any implementation.",
        "questions": [
            "Which context variables are useful for the chosen adaptation decision?",
            "What trade-offs appear between latency, resource use, and service quality?",
        ],
        "evidence": [],
        "risks": ["A generic mobile app or a broad platform is out of scope."],
    },
    {
        "name": "Static versus adaptive policies",
        "detail": "The comparison that would make the work empirical: a fixed policy against a policy that reacts.",
        "status_title": "Static policies are the obvious baseline",
        "status": "A static execution strategy is the baseline any adaptive policy has to beat. No workload traces or resource profiles have been selected, so this is a design note rather than a literature result.",
        "status_evidence": "hypothesis",
        "gap_title": "Adaptive policies may be tested on workloads that do not change",
        "gap": "Evaluations that use a narrow or static workload would not show whether a policy copes when bandwidth, energy, or connectivity changes. No papers have been reviewed for this candidate yet, so the gap is not confirmed.",
        "gap_status": "needs_literature",
        "topic": "Replay controlled resource profiles against a static baseline",
        "questions": [
            "How does the adaptive policy compare with a static baseline when resource availability changes?",
            "How stable is the policy when conditions change outside the profiles used to design it?",
        ],
        "evidence": [],
    },
    {
        "name": "What is being optimised",
        "detail": "Latency, energy, memory, bandwidth, and output quality are not interchangeable objectives.",
        "status_title": "The objective is unspecified",
        "status": "Until the objective and the acceptable quality level are named, experimental results would not answer a thesis question.",
        "status_evidence": "hypothesis",
        "gap_title": "Joint reporting of resource use and service quality is easy to omit",
        "gap": "A result that reports only energy, or only latency, would not answer whether service quality stayed acceptable. This is a requirement on the future study design, not a claim about the literature.",
        "gap_status": "hypothesis",
        "topic": "Report the trade-off, not a single winner",
        "questions": [
            "Which quality level counts as acceptable while resources are being reduced?",
        ],
        "evidence": [],
        "topic_tags": ["exploratory"],
    },
]

adaptive_nodes, adaptive_links = spine(
    "adaptive",
    "Adaptive",
    {
        "title": "Static behaviour under changing resources",
        "summary": "Systems that keep one execution strategy can fail when bandwidth, power, or connectivity changes.",
        "detail": "Computing systems often run under changing limits: bandwidth, intermittent connectivity, constrained processors, battery, or unreliable infrastructure. A static strategy may not respond. This candidate is not yet a thesis problem, because the system class and the adaptation decision are unspecified.",
        "risks": ["The topic stays an area survey unless one system and one decision are chosen."],
    },
    {
        "title": "How should a system change behaviour as resources change?",
        "summary": "How can a system adapt resource use or service behaviour and still hold an acceptable level of performance or quality?",
        "detail": "The question needs a defined system, a defined adaptation, and a defined notion of acceptable quality before it can be answered empirically.",
    },
    {
        "title": "A systems question, once it is bounded",
        "summary": "The contribution would be a policy and a comparison, not a user interface.",
        "detail": "The thesis has to investigate an algorithm or a system behaviour.",
        "ghana_title": "Infrastructure constraints are a possible setting",
        "ghana": "Unreliable connectivity and limited power are relevant in many Ghanaian deployments. That setting does not choose the system for the thesis.",
        "computing_title": "An adaptation policy with a measured trade-off",
        "computing": "The technical object would be a context-aware policy, a static baseline, and a comparison across defined resource profiles.",
        "contribution_title": "What would count as a contribution",
        "contribution": "A measurable policy for one system class, a controlled comparison with a static strategy, and an explicit trade-off among performance, resource use, and service quality.",
    },
    [
        ("A defined test environment", "One workload and a small set of resource profiles that can be reproduced."),
        ("A static baseline", "The same workload with no adaptation."),
        ("An adaptive policy", "One decision the system is allowed to change."),
        ("A trade-off report", "Latency, resource use, and quality reported together."),
    ],
    adaptive_areas,
)

adaptive_candidate = {
    "id": "adaptive",
    "title": "Context-aware adaptive computing under resource constraints",
    "shortTitle": "Adaptive computing",
    "workingTitle": "Context-Aware Adaptive Computing Under Resource Constraints",
    "summary": "A promising systems direction that is not yet a thesis, because the system and the adaptation decision are still open.",
    "shortDescription": "Asks how a bounded system should change behaviour as resources change, without pretending the scenario is chosen.",
    "priority": "primary",
    "status": "exploratory",
    "ghanaianRelevance": "Constrained connectivity and power are a plausible setting. They do not define the system under study.",
    "technicalContribution": "Not yet fixed. A contribution would be one adaptation policy and a comparison against a static baseline.",
    "feasibility": {
        "rating": "low",
        "rationale": "This is a planning assessment. The direction is technically workable only after the system class, decision, and metrics are chosen.",
    },
    "dataRequirements": None,
    "evaluationDesign": "Not specified until a workload and resource profiles exist.",
    "majorRisks": [
        "The topic is an area, not a problem, until the system boundary is fixed.",
        "No literature has been reviewed for this candidate.",
    ],
    "rootNodeId": "adaptive-problem",
    "tags": ["edge-computing", "adaptation", "resource-constraints"],
    "openDecisions": [
        "Which one system class and which one adaptation decision will the thesis study?",
        "What counts as acceptable service quality?",
    ],
    "readiness": readiness(
        [
            ("bounded", False, "The system class and adaptation decision are open."),
            ("contribution", False, "The contribution is described only in general terms."),
            ("literature", False, "A literature review has not been started in this catalogue."),
            ("fulltext", False, "There are no full-text-checked sources."),
            ("resources", False, "Workloads, traces, and devices are not chosen."),
            ("design", False, "The experiment cannot be specified before the system is."),
            ("mphil", False, "It can become an IT thesis, but it is not one yet."),
        ]
    ),
    "lastReviewed": REVIEWED,
}

se_areas = [
    {
        "name": "Cross-project generalisation",
        "detail": "Whether an effort model trained on one set of projects still works on another.",
        "status_title": "Studies use different datasets and protocols",
        "status": "The Scopus notes list Ali (2022), Pospieszny et al. (2018), Sousa et al. (2023), and several later comparisons. They do not yet show a single protocol. Reported accuracy may depend on the dataset, the project mix, and the validation strategy.",
        "status_evidence": "unverified",
        "gap_title": "Reported accuracy may not travel across projects or datasets",
        "gap": "The listed studies have not been reconciled, so it is not established here whether recent work already measures cross-project generalisation. The proposed gap is that accuracy is sensitive to dataset choice and validation strategy. It is a hypothesis.",
        "topic": "A leakage-aware comparison on a small set of public datasets",
        "questions": [
            "How well do selected effort models generalise across projects or datasets?",
            "How does temporal or project-domain shift change estimation error?",
        ],
        "evidence": [
            link("ev-se-0-ali", "se-gap-0", "pub-ali-2022", "supports_context", "Ali (2022) is recorded as a systematic comparison of machine-learning effort techniques.", "The datasets, splits, and whether leakage is discussed have not been extracted.", "contextual"),
            link("ev-se-0-pospieszny", "se-gap-0", "pub-pospieszny-2018", "supports_context", "Pospieszny, Czarnacka-Chrobot, and Kobyliński (2018) estimate effort and duration with machine learning.", "The validation protocol is unverified.", "contextual"),
        ],
        "risks": ["A generic algorithm bake-off on a familiar dataset is unlikely to be enough."],
    },
    {
        "name": "Uncertainty of an estimate",
        "detail": "Whether a model can say which tasks it should not be trusted on.",
        "status_title": "Point estimates dominate the notes",
        "status": "The identified papers are described as accuracy studies. It is not yet known which of them report prediction intervals or calibration.",
        "status_evidence": "needs_literature",
        "gap_title": "A point estimate can hide tasks that should not be trusted",
        "gap": "The project notes do not establish that current effort models report calibrated uncertainty. The suggestion is that uncertainty estimates might flag tasks whose predictions should be refused. That is unconfirmed.",
        "topic": "Uncertainty-aware estimates for task-level effort",
        "questions": [
            "Can uncertainty estimates identify tasks for which the model should not be trusted?",
        ],
        "evidence": [
            link("ev-se-1-sousa", "se-gap-1", "pub-sousa-2023", "supports_context", "Sousa et al. (2023) estimate effort and duration of individual tasks.", "Whether the paper reports uncertainty is unverified.", "contextual"),
        ],
    },
    {
        "name": "Task-level features, including LLM-derived ones",
        "detail": "Agile task estimates may need different inputs from classical project attributes.",
        "status_title": "Project-level attributes are the common feature set",
        "status": "Several of the listed papers appear to use project-level attributes. Sousa et al. (2023) and Chakravorty et al. (2025) are the leads that may sit closer to task-level or agile estimation. Neither has been read for this catalogue.",
        "status_evidence": "unverified",
        "gap_title": "It is unknown whether task-level or LLM-derived features change the estimate",
        "gap": "The notes do not show that LLM-derived task features improve on conventional project attributes. Treating that as a finding would overclaim. It is a possible comparison after the papers are read.",
        "topic": "Compare task-level features with conventional project attributes",
        "questions": [
            "Do task-level features improve estimates over conventional project-level attributes?",
        ],
        "evidence": [
            link("ev-se-2-chakravorty", "se-gap-2", "pub-chakravorty-2025", "supports_context", "Chakravorty, Reddy, and Khan (2025) are a lead on effort estimation in scrum-based projects.", "The framework and the evaluation are unverified.", "uncertain"),
            link("ev-se-2-mahdi", "se-gap-2", "pub-mahdi-2021", "supports_context", "Mahdi et al. (2021) are recorded as a review of machine learning in software project management.", "A review may already cover this ground. That has not been checked.", "contextual"),
        ],
    },
]

se_nodes, se_links = spine(
    "se",
    "Software effort",
    {
        "title": "Effort-estimation accuracy is hard to compare",
        "summary": "Machine-learning effort studies often cannot be lined up, because datasets, metrics, and splits differ.",
        "detail": "The direction is the reliability of AI-assisted software engineering, narrowed here to software effort estimation. A broad comparison of algorithms on one familiar dataset is unlikely to be a contribution. The Scopus notes already name a set of studies that still need reconciling.",
    },
    {
        "title": "Where does reported effort-estimation accuracy fail to generalise?",
        "summary": "How sensitive are selected effort models to the dataset, the project mix, leakage, and the validation protocol?",
        "detail": "The question has to land on one methodological issue: cross-project generalisation, temporal shift, uncertainty, or task-level features. It should not become a leaderboard.",
    },
    {
        "title": "A methodological contribution, if one gap is chosen",
        "summary": "The literature base is large. The thesis needs one defensible hole in how estimation is evaluated.",
        "detail": "Novelty is not claimed. The catalogue only records that a distinctive gap still has to be selected from the Scopus analysis.",
        "ghana_title": "No Ghana-specific claim is made",
        "ghana": "Nothing in the current notes ties this candidate to a Ghanaian dataset or practice. Do not add one without evidence.",
        "computing_title": "Evaluation of predictive models",
        "computing": "The technical work would be a reproducible benchmark protocol and a test of whether conclusions change under a stricter validation strategy.",
        "contribution_title": "What would count as a contribution",
        "contribution": "A controlled comparison that isolates leakage, shift, or task-level features, with fixed baselines. Not a new regression model by itself.",
    },
    [
        ("A reconciled study table", "Dataset, target, features, split, metrics, and replication status for each listed paper."),
        ("One methodological focus", "A single gap chosen from generalisation, leakage, uncertainty, or task-level estimation."),
        ("A repeatable protocol", "The same baselines under at least two validation strategies."),
    ],
    se_areas,
)

se_candidate = {
    "id": "se",
    "title": "Reliability of machine-learning software effort estimation",
    "shortTitle": "Effort estimation",
    "workingTitle": "Reliability of machine-learning software effort estimation",
    "summary": "An alternative direction: find one methodological gap in effort estimation, rather than comparing algorithms again.",
    "shortDescription": "Alternative. The Scopus notes name a literature; they do not yet name a single defensible gap.",
    "priority": "alternative",
    "status": "exploratory",
    "ghanaianRelevance": None,
    "technicalContribution": "Undecided. A defensible contribution would be methodological: leakage, shift, uncertainty, or task-level features.",
    "feasibility": {
        "rating": "medium",
        "rationale": "This is a planning assessment. Public datasets exist in this literature, but the gap is not chosen.",
    },
    "dataRequirements": "The public datasets used by the reconciled studies, once those datasets are identified from the papers.",
    "evaluationDesign": "Not fixed. It should not be a generic algorithm comparison.",
    "majorRisks": ["A familiar dataset comparison is unlikely to be novel."],
    "rootNodeId": "se-problem",
    "tags": ["software-engineering", "effort-estimation", "alternative"],
    "openDecisions": ["Which one methodological gap survives a reading of the Scopus set?"],
    "readiness": readiness(
        [
            ("bounded", False, "Several possible problems are listed. One is not chosen."),
            ("contribution", False, "The contribution is a menu, not a claim."),
            ("literature", False, "Citations are listed from Scopus notes and are not reconciled."),
            ("fulltext", False, "No paper is marked full-text checked."),
            ("resources", False, "Datasets are not yet named from the papers."),
            ("design", False, "The protocol depends on the gap that is chosen."),
            ("mphil", True, "A narrow evaluation study would fit an IT MPhil."),
        ]
    ),
    "lastReviewed": REVIEWED,
}

language_areas = [
    {
        "name": "What is actually measured",
        "detail": "Aggregate benchmark scores can hide errors that change meaning.",
        "status_title": "Coverage for Ghanaian languages is not mapped here",
        "status": "Khaya AI reports, African NLP benchmarks, and multilingual evaluations are the kinds of sources that would need to be separated into papers, model cards, and project pages. None of those records has been added, because the bibliographic details are not in the project notes.",
        "status_evidence": "needs_literature",
        "gap_title": "Benchmark averages may hide errors that matter to a reader",
        "gap": "It is a hypothesis that fluent output in an underrepresented Ghanaian language can still be inaccurate or contextually wrong, and that translation-based evaluation can conceal that. No evidence matrix exists yet.",
        "gap_status": "needs_literature",
        "topic": "One task, one or two languages, a controlled error analysis",
        "questions": [
            "How reliable are selected models on one bounded task in one selected Ghanaian language?",
            "How do code-switching and orthographic variation change that result?",
        ],
        "evidence": [],
        "risks": [
            "Dataset construction and native-speaker validation are major dependencies.",
            "The topic is too broad until the language and the task are named.",
        ],
    }
]

language_nodes, language_links = spine(
    "language",
    "Ghanaian languages",
    {
        "title": "Fluent output in a Ghanaian language may still be unreliable",
        "summary": "General-purpose models can sound fluent in underrepresented Ghanaian languages while being inaccurate or contextually wrong.",
        "detail": "The direction is the reliability of AI on Ghanaian languages for a bounded task. It is not a general low-resource language project. No language or task has been selected.",
    },
    {
        "title": "How reliable is a bounded task in a selected Ghanaian language?",
        "summary": "How reliable are selected models on one task, in one or two Ghanaian languages, once code-switching and spelling variation are included?",
        "detail": "The question is only meaningful after the language, the task, and the model set are fixed.",
    },
    {
        "title": "An evaluation contribution, if the task is narrow",
        "summary": "A benchmark or an error analysis can be a computing contribution. A broad language survey cannot.",
        "detail": "The contribution would be a carefully built evaluation, a reliability analysis, or a method for factual or semantic consistency on a bounded task.",
        "ghana_title": "The languages are the object of evaluation",
        "ghana": "The candidate is about Ghanaian languages. Which languages, and whose judgements count as validation, are unresolved.",
        "computing_title": "Evaluation, not a new general model",
        "computing": "The technical work would be a test set, an error taxonomy, and a comparison. Training a general language model is out of scope.",
        "contribution_title": "What would count as a contribution",
        "contribution": "A documented evaluation for one task and a small language set, with agreement checks if people annotate errors.",
    },
    [
        ("A named language and task", "One or two languages and one task, chosen before data collection."),
        ("A small evaluation set", "Items that can be checked by speakers of that language."),
        ("An error analysis", "Categories that distinguish fluency from semantic correctness."),
    ],
    language_areas,
)

language_candidate = {
    "id": "language",
    "title": "Reliability of AI systems on Ghanaian languages",
    "shortTitle": "Ghanaian-language AI",
    "workingTitle": "Reliability of AI systems on Ghanaian languages",
    "summary": "An alternative. Promising only after one language and one task are chosen, and only with speaker validation.",
    "shortDescription": "Alternative. Reliability of models on a bounded Ghanaian-language task. No sources are recorded yet.",
    "priority": "alternative",
    "status": "exploratory",
    "ghanaianRelevance": "The subject is Ghanaian languages. The evaluation is only as good as the language choice and the speakers who check it.",
    "technicalContribution": "A bounded evaluation or error analysis. Not claimed as novel.",
    "feasibility": {
        "rating": "low",
        "rationale": "This is a planning assessment. Dataset construction and native-speaker validation are heavy dependencies.",
    },
    "dataRequirements": "Text for one task in one or two languages, with a way for speakers to judge correctness. Licensing has to be settled first.",
    "evaluationDesign": "Not specified beyond a controlled comparison and a structured error analysis.",
    "majorRisks": ["The topic is too broad to start data collection.", "Speaker validation may not be available."],
    "rootNodeId": "language-problem",
    "tags": ["nlp", "low-resource", "ghana", "alternative"],
    "openDecisions": ["Which language, which task, and which models?"],
    "readiness": readiness(
        [
            ("bounded", False, "Language and task are not chosen."),
            ("contribution", False, "The contribution is a direction, not a design."),
            ("literature", False, "No bibliographic records are in the catalogue."),
            ("fulltext", False, "Nothing has been full-text checked."),
            ("resources", False, "Data and speaker access are unresolved."),
            ("design", False, "The evaluation is only sketched."),
            ("mphil", False, "It could fit, but not in the current unbounded form."),
        ]
    ),
    "lastReviewed": REVIEWED,
}

context_areas = [
    {
        "name": "Whether this is still an IT thesis",
        "detail": "Readiness frameworks already cover technical, human, organisational, and policy factors. A new questionnaire is not automatically a computing contribution.",
        "status_title": "Existing readiness frameworks use similar dimensions",
        "status": "Earlier versions of this idea mixed technical, human, organisational, and policy readiness, including trust, self-efficacy, anxiety, infrastructure, and governance. Those dimensions are already used in published readiness work. No specific framework has been entered as a verified citation.",
        "status_evidence": "needs_literature",
        "gap_title": "A further readiness score may not add a computational result",
        "gap": "It has not been shown that a new assessment would provide information beyond existing readiness frameworks, or that country-level public datasets can stand in for institution-level observations. The supervisor's concern that the framing is social-science heavy is recorded as an open risk, not as a literature finding.",
        "gap_status": "needs_literature",
        "topic": "Park this direction unless a computational method is specified",
        "topic_detail": "Proceed only if there is a technically substantive artefact or method that can be evaluated. Do not revive it because data collection looks easier.",
        "questions": [
            "Which measurable factors, at a defined unit of analysis, add information beyond an existing readiness framework?",
            "How stable are any scores when inputs are missing?",
        ],
        "evidence": [],
        "topic_tags": ["exploratory"],
        "risks": [
            "Country-level indicators are not institution-level observations.",
            "Sample size, data access, and framework novelty were unresolved in the earlier concept.",
        ],
    }
]

context_nodes, context_links = spine(
    "context",
    "Digital interventions",
    {
        "title": "Suitability of a digital intervention is easy to overclaim",
        "summary": "Asking whether a digital intervention fits its context can collapse into a social survey unless the computational contribution is explicit.",
        "detail": "This direction grew out of an AI-assisted ICT policy readiness idea. The current concern is that similar frameworks already exist, the unit of analysis was unclear, and the work risked leaving information technology. It is parked.",
        "status": "hypothesis",
    },
    {
        "title": "What would a computational suitability judgement add?",
        "summary": "Which measurable factors predict suitability for one narrow class of digital intervention, beyond existing readiness frameworks?",
        "detail": "The question is worth keeping only as a boundary. It is not a proposal.",
    },
    {
        "title": "Kept as a warning, not a candidate to build",
        "summary": "The earlier concept had unresolved originality, data-unit, and method problems.",
        "detail": "The catalogue keeps the direction so it is not quietly restarted under a new name.",
        "ghana_title": "A Ghanaian institutional setting was the earlier context",
        "ghana": "The earlier concept referred to Ghanaian institutions. Public country indicators still cannot be treated as observations of those institutions.",
        "computing_title": "An IT contribution is not currently stated",
        "computing": "Trust, self-efficacy, and anxiety scales are not, by themselves, a computing method. A decision-support or measurement model would need a separate technical evaluation.",
        "contribution_title": "No contribution is claimed",
        "contribution": "No differentiated measurement model is proposed. The entry records why the earlier concept should stay parked.",
    },
    [
        ("A unit of analysis", "Something that is not a country indicator pretending to be an institution."),
        ("A comparison with an existing framework", "Evidence that a new score adds information, if the direction is ever reopened."),
        ("A technical evaluation", "A method or artefact whose outputs can be checked when inputs are missing."),
    ],
    context_areas,
)

context_candidate = {
    "id": "context",
    "title": "Contextual suitability of digital interventions",
    "shortTitle": "Digital-intervention suitability",
    "workingTitle": "Contextual suitability of digital interventions",
    "summary": "Parked. The earlier readiness concept was at risk of becoming a social-science study without a distinct IT contribution.",
    "shortDescription": "Exploratory and parked. Kept so the earlier concept is not restarted by accident.",
    "priority": "exploratory",
    "status": "parked",
    "ghanaianRelevance": "The earlier setting was institutional and Ghanaian. That does not repair the unit-of-analysis problem.",
    "technicalContribution": None,
    "feasibility": {
        "rating": "low",
        "rationale": "This is a planning assessment. The direction should not proceed on the current framing.",
    },
    "dataRequirements": None,
    "evaluationDesign": None,
    "majorRisks": [
        "Originality against existing readiness frameworks was not shown.",
        "Country-level data cannot stand in for institutions.",
    ],
    "rootNodeId": "context-problem",
    "tags": ["readiness", "parked", "exploratory"],
    "openDecisions": ["Leave parked unless a computational method and a unit of analysis are both specified."],
    "readiness": readiness(
        [
            ("bounded", False, "The intervention class and the unit of analysis are unresolved."),
            ("contribution", False, "No IT contribution is stated."),
            ("literature", False, "Existing frameworks are acknowledged but not yet cited as verified records."),
            ("fulltext", False, "No full-text review is recorded."),
            ("resources", False, "Institutional data access is unresolved."),
            ("design", False, "There is no evaluation design."),
            ("mphil", False, "On the current framing it is not clearly an IT thesis."),
        ]
    ),
    "lastReviewed": REVIEWED,
}


def write_all():
    CANDIDATES.mkdir(parents=True, exist_ok=True)
    PUBLICATIONS.mkdir(parents=True, exist_ok=True)
    dump(
        PUBLICATIONS / "kente.json",
        {"schemaVersion": "1.0.0", "publications": kente_pubs},
    )
    dump(
        CANDIDATES / "kente_generation.json",
        candidate_doc(
            kente_candidate,
            kente_nodes,
            kente_links,
            [
                {
                    "id": "kente-cross-eval",
                    "sourceNodeId": "kente-gap-2",
                    "targetNodeId": "kente-gap-0",
                    "relationshipType": "related_to",
                    "visualStyle": "dashed",
                }
            ],
        ),
    )
    print(f"kente nodes {len(kente_nodes)} links {len(kente_links)}")
    specs = [
        ("crop_disease.json", crop_pubs, "crop_disease_reliability.json", crop_candidate, crop_nodes, crop_links, []),
        ("adaptive_computing.json", adaptive_pubs, "adaptive_resource_aware_computing.json", adaptive_candidate, adaptive_nodes, adaptive_links, []),
        ("software_engineering.json", se_pubs, "ai_software_engineering.json", se_candidate, se_nodes, se_links, []),
        ("language_ai.json", language_pubs, "ghanaian_language_ai.json", language_candidate, language_nodes, language_links, []),
        ("digital_suitability.json", context_pubs, "contextual_suitability.json", context_candidate, context_nodes, context_links, []),
    ]
    for pub_name, pubs, cand_name, cand, nodes, links, crosses in specs:
        dump(PUBLICATIONS / pub_name, {"schemaVersion": "1.0.0", "publications": pubs})
        dump(CANDIDATES / cand_name, candidate_doc(cand, nodes, links, crosses))
        print(f"{cand['id']} nodes {len(nodes)} links {len(links)}")
    dump(
        ROOT / "assets" / "data" / "manifest.json",
        {
            "schemaVersion": "1.0.0",
            "catalogueTitle": "MPhil IT Thesis Topic Explorer",
            "lastReviewed": REVIEWED,
            "candidates": [
                "assets/data/candidates/kente_generation.json",
                "assets/data/candidates/crop_disease_reliability.json",
                "assets/data/candidates/adaptive_resource_aware_computing.json",
                "assets/data/candidates/ai_software_engineering.json",
                "assets/data/candidates/ghanaian_language_ai.json",
                "assets/data/candidates/contextual_suitability.json",
            ],
            "publications": [
                "assets/data/publications/kente.json",
                "assets/data/publications/crop_disease.json",
                "assets/data/publications/adaptive_computing.json",
                "assets/data/publications/software_engineering.json",
                "assets/data/publications/language_ai.json",
                "assets/data/publications/digital_suitability.json",
            ],
        },
    )


if __name__ == "__main__":
    write_all()
