From elpi Require Import elpi.
From Coq Require Import ssrbool.
From Coq Require Import PArith.
From elpi.apps.derive Extra Dependency "fields.elpi" as fields.
From elpi.apps.derive Extra Dependency "eqb.elpi" as eqb.
From elpi.apps.derive Extra Dependency "eqType.elpi" as eqType.

Require Import eqb_core_defs.
Require Export eqType_ast tag fields.

Register eqb_body as elpi.derive.eqb_body.

Elpi Db derive.eqbcorrect.db lp:{{

  pred eqcorrect-for
    o:inductive,
    o:constant, % correct
    o:constant. % reflexive 

  :index(2)
  pred correct-lemma-for i:term, o:term.

  :index(2)
  pred refl-lemma-for i:term, o:term. 

}}.

Elpi Command derive.eqb.

Elpi Accumulate Db derive.tag.db.
Elpi Accumulate Db derive.eqType.db.
Elpi Accumulate Db derive.fields.db.
Elpi Accumulate Db derive.eqb.db.
Elpi Accumulate Db derive.eqbcorrect.db.
Elpi Accumulate File fields.
Elpi Accumulate File eqb.
Elpi Accumulate File eqType.

Elpi Accumulate lp:{{

  main [str I, str O] :- !, 
    coq.locate I (indt GR), 
    Prefix is O ^ "_",
    derive.eqb.main GR Prefix _.

  main [str I] :- !, 
    coq.locate I (indt GR),
    coq.gref->id (indt GR) Tname,
    Prefix is Tname ^ "_",
    derive.eqb.main GR Prefix _.

  main _ :- usage.
   
  usage :- coq.error "Usage: derive.eqb <inductive name> [<prefix>]".

}}.
Elpi Typecheck.
