create or replace TRIGGER EXTR_SRVC_TRIG_UPD_STATUS

AFTER UPDATE ON EXETR_SRVC_TASK

REFERENCING NEW AS NEW

FOR EACH ROW

BEGIN

INSERT

INTO EXETR_SRVC_TASK_STATUS

  (
    EXETR_SRVC_TASK_STATUS_ID,
    EXETR_SRVC_TASK_ID,
    DELIV_STATUS_CD,
    DELIV_TIME
  )

  VALUES

  (
    EXETR_SRVC_TASK_STAT_SEQ.NEXTVAL,
    :new.EXETR_SRVC_TASK_ID,
    :new.TRANS_STATUS,
    sysdate

  );

if :NEW.TRANS_STATUS = 'DELIV' then 

  INSERT
INTO ACTV_SLA_INSTANCE
  (
    ACTV_SLA_INSTANCE_ID,
    SLA_INSTANCE_REF_ID,
    SLA_INSTANCE_REF_TYPE,
    SLA_INSTANCE_CRN,
    SLA_INSTANCE_DUEDATE,
    SLA_INSTANCE_CURR_REPET,
    SLA_INSTANCE_MAX_REPET,
    SLA_ENTITY_ID
  )
  (select ACTV_SLA_INSTANCE_SEQ.NEXTVAL,
    :NEW.AGCY_SRVC_REQST_ID,
    'FI_'||:NEW.CHANNEL_CD,
    SRVC_REQST_COR_RN,
    GET_SLA_DUEDATE(SRVC_TYPE_CD,'FI',:NEW.CHANNEL_CD,'0'),
    0,
    3,
    :NEW.FIN_INST_CD 
    from AGCY_SRVC_REQST where AGCY_SRVC_REQST_ID=:NEW.AGCY_SRVC_REQST_ID
    );
  end if;


if :NEW.TRANS_STATUS = 'DELIV'  and  :NEW.CHANNEL_CD = 'Portal' then 

  INSERT INTO FIPORTAL.WORKFLOW_TASK 
  (
    ID,
    EXETR_SRVC_TASK_ID,
    REQUEST_METADATA_ID,
    FI_ID,
    CREATED_DATE_TIME,
    MSGUID,
    SRN,
    PROCESS_TYPE_CD,
    SRVC_TYPE_CD,
    BUS_SRVC_CD,
    REQSTR_CD,
    PHASH,
    DUE_DATE_TIME
  )
  
    (select FIPORTAL.WORKFLOW_TASK_ID.NEXTVAL,
    :new.EXETR_SRVC_TASK_ID,
    :new.AGCY_SRVC_REQST_ID,
    :new.FIN_INST_CD,
    sysdate,
    :new.EXETR_REF_NO,
    SRVC_REQST_COR_RN,
    PROCESS_TYPE_CD,
    SRVC_TYPE_CD,
    BUS_SRVC_CD,
    REQSTR_CD,
    PHASH,
    GET_SLA_DUEDATE(SRVC_TYPE_CD,'FIP','Portal',0)
    from TANFEETH.AGCY_SRVC_REQST where AGCY_SRVC_REQST_ID=:new.AGCY_SRVC_REQST_ID
    );
  end if;

  
   if :NEW.TRANS_STATUS = 'RECIV' then 
    DELETE FROM ACTV_SLA_INSTANCE where SLA_INSTANCE_REF_ID = :NEW.AGCY_SRVC_REQST_ID and SLA_ENTITY_ID = :NEW.FIN_INST_CD;
  end if;

END;